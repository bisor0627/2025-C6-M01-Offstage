// 버스온다 relay (Cloudflare Worker).
//
//   GET /v1/tago/<Service>/<operation>?...   국토교통부 TAGO (apis.data.go.kr/1613000)
//   GET /v1/seoul/<group>/<operation>?...    서울 버스 (ws.bus.go.kr/api/rest, http only)
//
// Only the operations the app calls are allowed (ROUTES). The relay adds the
// data.go.kr key (one key per account covers both providers) and forces JSON,
// so the app ships no keys and needs no ATS exception for ws.bus.go.kr.
//
// Guards: 60 requests per minute per IP (429), and a daily cap per upstream
// service counted only on cache misses (503 until midnight KST) so the key
// never hits its own quota. The free Workers plan refuses requests past its
// limit; nothing is billed.
//
// Responses are the upstream JSON unchanged. Upstream key/quota errors are not
// cached and come back as 502, so the app can tell them from "no buses".

const SEC = 1;
const DAY = 24 * 60 * 60;

/// path → { service: daily-cap bucket, ttl: edge cache seconds }
export const ROUTES = {
  tago: {
    'BusLcInfoInqireService/getCtyCodeList': { service: 'tago-location', ttl: 7 * DAY },
    'BusLcInfoInqireService/getRouteAcctoBusLcList': { service: 'tago-location', ttl: 15 * SEC },
    'BusSttnInfoInqireService/getCtyCodeList': { service: 'tago-stop', ttl: 7 * DAY },
    'BusSttnInfoInqireService/getSttnNoList': { service: 'tago-stop', ttl: DAY },
    'BusSttnInfoInqireService/getCrdntPrxmtSttnList': { service: 'tago-stop', ttl: DAY },
    'BusSttnInfoInqireService/getSttnThrghRouteList': { service: 'tago-stop', ttl: DAY },
    'BusRouteInfoInqireService/getCtyCodeList': { service: 'tago-route', ttl: 7 * DAY },
    'BusRouteInfoInqireService/getRouteInfoIem': { service: 'tago-route', ttl: DAY },
    'BusRouteInfoInqireService/getRouteNoList': { service: 'tago-route', ttl: DAY },
    'BusRouteInfoInqireService/getRouteAcctoThrghSttnList': { service: 'tago-route', ttl: DAY },
    'ArvlInfoInqireService/getCtyCodeList': { service: 'tago-arrival', ttl: 7 * DAY },
    'ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList': { service: 'tago-arrival', ttl: 15 * SEC },
    'ArvlInfoInqireService/getSttnAcctoSpcifyRouteBusArvlPrearngeInfoList': { service: 'tago-arrival', ttl: 15 * SEC },
  },
  seoul: {
    'stationinfo/getStationByName': { service: 'seoul-station', ttl: DAY },
    'stationinfo/getStationByPos': { service: 'seoul-station', ttl: DAY },
    'stationinfo/getRouteByStation': { service: 'seoul-station', ttl: DAY },
    'stationinfo/getStationByUid': { service: 'seoul-station', ttl: 15 * SEC },
    'busRouteInfo/getBusRouteList': { service: 'seoul-route', ttl: DAY },
    'busRouteInfo/getStaionByRoute': { service: 'seoul-route', ttl: DAY },
    'arrive/getArrInfoByRoute': { service: 'seoul-arrival', ttl: 15 * SEC },
    'buspos/getBusPosByRtid': { service: 'seoul-buspos', ttl: 15 * SEC },
  },
};

const UPSTREAM = {
  tago: { base: 'https://apis.data.go.kr/1613000/', format: ['_type', 'json'] },
  seoul: { base: 'http://ws.bus.go.kr/api/rest/', format: ['resultType', 'json'] },
};

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET') return json({ error: 'method' }, 405);
    const url = new URL(request.url);
    const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
    if (env.PER_IP) {
      const { success } = await env.PER_IP.limit({ key: ip });
      if (!success) return json({ error: 'rate' }, 429);
    }

    const route = matchRoute(url.pathname);
    if (!route) return json({ error: 'not found' }, 404);

    const query = cleanQuery(url.searchParams, route.provider);
    const cacheKey = `${url.origin}/v1/${route.provider}/${route.path}?${query}`;
    return cached(cacheKey, ctx, route.ttl, async () => {
      const cap = route.provider === 'tago' ? env.TAGO_DAILY_CAP : env.SEOUL_DAILY_CAP;
      if (!(await spend(env, route.service, cap))) return capped();
      const upstream = `${UPSTREAM[route.provider].base}${route.path}?serviceKey=${encodeURIComponent(env.DATA_GO_KR_KEY)}&${query}`;
      const res = await fetch(upstream, { headers: { accept: 'application/json' } });
      const body = await res.text();
      const ok = res.ok && isAnswer(route.provider, body);
      return { body, status: ok ? 200 : 502, cache: ok };
    });
  },
};

/// "/v1/tago/ArvlInfoInqireService/getCtyCodeList" → route entry, or null.
export function matchRoute(pathname) {
  const m = pathname.match(/^\/v1\/(tago|seoul)\/([A-Za-z]+\/[A-Za-z]+)$/);
  if (!m) return null;
  const entry = ROUTES[m[1]][m[2]];
  return entry ? { provider: m[1], path: m[2], ...entry } : null;
}

/// Drops any client-sent key or format, forces JSON, and sorts the rest so the
/// same request always hits the same cache entry.
export function cleanQuery(params, provider) {
  const kept = [...params].filter(([k]) => !['servicekey', '_type', 'resulttype'].includes(k.toLowerCase()));
  kept.push(UPSTREAM[provider].format);
  kept.sort(([a], [b]) => (a < b ? -1 : a > b ? 1 : 0));
  return new URLSearchParams(kept).toString();
}

/// True when the body is a real answer (including "no results"), false for
/// key, quota and service errors.
export function isAnswer(provider, body) {
  let data;
  try {
    data = JSON.parse(body);
  } catch {
    return false;
  }
  if (provider === 'tago') {
    // 00 OK, 03 NODATA. Key/quota errors come as OpenAPI_ServiceResponse instead.
    const code = data?.response?.header?.resultCode;
    return code === '00' || code === '03';
  }
  // 0 OK, 4 결과없음. 401 JSON or other headerCd (7 인증, 8 요청제한) are errors.
  const code = String(data?.msgHeader?.headerCd ?? '');
  return code === '0' || code === '4';
}

/// One counter per upstream service per day (KST), in one Durable Object.
export class DailyCounter {
  constructor(state) {
    this.storage = state.storage;
  }

  async fetch(request) {
    const url = new URL(request.url);
    const service = url.searchParams.get('service');
    const cap = Number(url.searchParams.get('cap')) || 0;
    const day = new Date(Date.now() + 9 * 3600 * 1000).toISOString().slice(0, 10);
    const key = `${service}:${day}`;
    const used = ((await this.storage.get(key)) ?? 0) + 1;
    if (cap > 0 && used > cap) return new Response('capped', { status: 429 });
    await this.storage.put(key, used);
    return new Response(String(used));
  }
}

async function spend(env, service, cap) {
  const counter = env.COUNTER.get(env.COUNTER.idFromName('daily'));
  const res = await counter.fetch(`https://counter/?service=${service}&cap=${Number(cap) || 0}`);
  return res.ok;
}

const capped = () => ({ body: JSON.stringify({ error: 'daily cap' }), status: 503, cache: false });

async function cached(cacheKey, ctx, ttl, load) {
  const cache = caches.default;
  const key = new Request(cacheKey, { method: 'GET' });
  const hit = await cache.match(key);
  if (hit) return hit;
  const { body, status, cache: keep } = await load();
  const res = new Response(body, {
    status,
    headers: {
      'content-type': 'application/json; charset=utf-8',
      'cache-control': keep ? `public, max-age=${ttl}` : 'no-store',
    },
  });
  if (keep) ctx.waitUntil(cache.put(key, res.clone()));
  return res;
}

const json = (obj, status) =>
  new Response(JSON.stringify(obj), { status, headers: { 'content-type': 'application/json; charset=utf-8' } });
