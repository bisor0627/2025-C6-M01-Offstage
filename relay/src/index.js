// 버스온다 relay (Cloudflare Worker).
//
//   GET /v1/tago/<Service>/<operation>?...   국토교통부 TAGO (apis.data.go.kr/1613000)
//   GET /v1/seoul/<group>/<operation>?...    서울 버스 (ws.bus.go.kr/api/rest, http only)
//
// Only the operations the app calls are allowed (ROUTES). The relay adds the
// data.go.kr key (one key per account covers both providers) and forces JSON,
// so the app ships no keys and needs no ATS exception for ws.bus.go.kr.
//
// Guards: 60 requests per minute per IP (429); per day, counted only on cache
// misses, a cap per IP (429) so one client can't use up the shared quota, and a
// cap per upstream service (503 until midnight KST) so the key never hits its
// own quota. IPs are only kept as a per-day hash. The free Workers plan refuses requests past its
// limit; nothing is billed.
//
// Responses are the upstream JSON unchanged. Upstream key/quota errors are not
// cached and come back as 502, so the app can tell them from "no buses".

const SEC = 1;
const DAY = 24 * 60 * 60;

/// path → { service: daily-cap bucket, ttl: edge cache seconds, params: query
/// parameters passed upstream }. Anything else in the query is dropped, so junk
/// parameters can't make every request a cache miss.
const PAGE = ['pageNo', 'numOfRows'];
export const ROUTES = {
  tago: {
    'BusLcInfoInqireService/getCtyCodeList': { service: 'tago-location', ttl: 7 * DAY, params: [] },
    'BusLcInfoInqireService/getRouteAcctoBusLcList': { service: 'tago-location', ttl: 10 * SEC, params: ['cityCode', 'routeId', ...PAGE] },
    'BusSttnInfoInqireService/getCtyCodeList': { service: 'tago-stop', ttl: 7 * DAY, params: [] },
    'BusSttnInfoInqireService/getSttnNoList': { service: 'tago-stop', ttl: DAY, params: ['cityCode', 'nodeNm', 'nodeNo', ...PAGE] },
    // User coordinates: never cached.
    'BusSttnInfoInqireService/getCrdntPrxmtSttnList': { service: 'tago-stop', ttl: 0, params: ['gpsLati', 'gpsLong', ...PAGE] },
    'BusSttnInfoInqireService/getSttnThrghRouteList': { service: 'tago-stop', ttl: DAY, params: ['cityCode', 'nodeid', ...PAGE] },
    'BusRouteInfoInqireService/getCtyCodeList': { service: 'tago-route', ttl: 7 * DAY, params: [] },
    'BusRouteInfoInqireService/getRouteInfoIem': { service: 'tago-route', ttl: DAY, params: ['cityCode', 'routeId'] },
    'BusRouteInfoInqireService/getRouteNoList': { service: 'tago-route', ttl: DAY, params: ['cityCode', 'routeNo', ...PAGE] },
    'BusRouteInfoInqireService/getRouteAcctoThrghSttnList': { service: 'tago-route', ttl: DAY, params: ['cityCode', 'routeId', ...PAGE] },
    'ArvlInfoInqireService/getCtyCodeList': { service: 'tago-arrival', ttl: 7 * DAY, params: [] },
    'ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList': { service: 'tago-arrival', ttl: 10 * SEC, params: ['cityCode', 'nodeId', ...PAGE] },
    'ArvlInfoInqireService/getSttnAcctoSpcifyRouteBusArvlPrearngeInfoList': { service: 'tago-arrival', ttl: 10 * SEC, params: ['cityCode', 'nodeId', 'routeId', ...PAGE] },
  },
  seoul: {
    'stationinfo/getStationByName': { service: 'seoul-station', ttl: DAY, params: ['stSrch'] },
    // User coordinates: never cached.
    'stationinfo/getStationByPos': { service: 'seoul-station', ttl: 0, params: ['tmX', 'tmY', 'radius'] },
    'stationinfo/getRouteByStation': { service: 'seoul-station', ttl: DAY, params: ['arsId'] },
    'stationinfo/getStationByUid': { service: 'seoul-station', ttl: 10 * SEC, params: ['arsId'] },
    'busRouteInfo/getBusRouteList': { service: 'seoul-route', ttl: DAY, params: ['strSrch'] },
    'busRouteInfo/getRouteInfo': { service: 'seoul-route', ttl: DAY, params: ['busRouteId'] },
    'busRouteInfo/getStaionByRoute': { service: 'seoul-route', ttl: DAY, params: ['busRouteId'] },
    'arrive/getArrInfoByRoute': { service: 'seoul-arrival', ttl: 10 * SEC, params: ['stId', 'busRouteId', 'ord'] },
    'buspos/getBusPosByRtid': { service: 'seoul-buspos', ttl: 10 * SEC, params: ['busRouteId'] },
  },
};

const UPSTREAM = {
  tago: { base: 'https://apis.data.go.kr/1613000/', format: ['_type', 'json'] },
  seoul: { base: 'http://ws.bus.go.kr/api/rest/', format: ['resultType', 'json'] },
};

export default {
  async fetch(request, env, ctx) {
    if (request.method !== 'GET') return json({ error: 'method' }, 405);
    // Without the secret every upstream answer is a key error; say so instead.
    if (!env.DATA_GO_KR_KEY) return json({ error: 'key not configured' }, 500);
    const url = new URL(request.url);
    const ip = request.headers.get('cf-connecting-ip') ?? 'unknown';
    if (env.PER_IP) {
      const { success } = await env.PER_IP.limit({ key: ip });
      if (!success) return json({ error: 'rate' }, 429);
    }

    const route = matchRoute(url.pathname);
    if (!route) return json({ error: 'not found' }, 404);

    const query = cleanQuery(url.searchParams, route);
    const cacheKey = `${url.origin}/v1/${route.provider}/${route.path}?${query}`;
    return cached(cacheKey, ctx, route.ttl, async () => {
      const cap = route.provider === 'tago' ? env.TAGO_DAILY_CAP : env.SEOUL_DAILY_CAP;
      const spent = await spend(env, route.service, cap, await ipHash(ip), env.IP_DAILY_CAP);
      if (spent === 'ip') return { body: JSON.stringify({ error: 'rate' }), status: 429, cache: false };
      if (spent === 'service') return capped();
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

/// Keeps only the route's own parameters (so no client key, format or junk),
/// forces JSON, and sorts them so the same request always hits the same cache entry.
export function cleanQuery(params, route) {
  const kept = [...params].filter(([k]) => route.params.includes(k));
  kept.push(UPSTREAM[route.provider].format);
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

/// Daily counters (KST) for each upstream service and each client, in one
/// Durable Object. Yesterday's counters are dropped on the first call of a day.
export class DailyCounter {
  constructor(state) {
    this.storage = state.storage;
  }

  async fetch(request) {
    const url = new URL(request.url);
    const service = url.searchParams.get('service');
    const cap = Number(url.searchParams.get('cap')) || 0;
    const client = url.searchParams.get('client');
    const clientCap = Number(url.searchParams.get('clientCap')) || 0;
    const day = kstDay();
    if ((await this.storage.get('day')) !== day) {
      await this.storage.deleteAll();
      await this.storage.put('day', day);
    }
    const clientKey = `client:${client}`;
    const clientUsed = ((await this.storage.get(clientKey)) ?? 0) + 1;
    if (client && clientCap > 0 && clientUsed > clientCap) return new Response('ip', { status: 429 });
    const serviceKey = `service:${service}`;
    const used = ((await this.storage.get(serviceKey)) ?? 0) + 1;
    if (cap > 0 && used > cap) return new Response('service', { status: 429 });
    await this.storage.put({ [serviceKey]: used, [clientKey]: clientUsed });
    return new Response(String(used));
  }
}

/// 'ok', or which daily cap refused the call: 'ip' or 'service'.
async function spend(env, service, cap, client, clientCap) {
  const counter = env.COUNTER.get(env.COUNTER.idFromName('daily'));
  const query = new URLSearchParams({ service, cap: String(Number(cap) || 0), client, clientCap: String(Number(clientCap) || 0) });
  const res = await counter.fetch(`https://counter/?${query}`);
  return res.ok ? 'ok' : await res.text();
}

/// A per-day hash of the client IP, so the counter never stores the address.
export async function ipHash(ip, day = kstDay()) {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(`${day}:${ip}`));
  return [...new Uint8Array(digest).slice(0, 8)].map((b) => b.toString(16).padStart(2, '0')).join('');
}

const kstDay = () => new Date(Date.now() + 9 * 3600 * 1000).toISOString().slice(0, 10);

const capped = () => ({ body: JSON.stringify({ error: 'daily cap' }), status: 503, cache: false });

async function cached(cacheKey, ctx, ttl, load) {
  const cache = caches.default;
  const key = new Request(cacheKey, { method: 'GET' });
  const hit = ttl > 0 ? await cache.match(key) : undefined;
  if (hit) return hit;
  const { body, status, cache: ok } = await load();
  const keep = ok && ttl > 0;
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
