# 버스온다 relay

A Cloudflare Worker between the app and the public bus APIs, so release builds
carry no API keys and repeated lookups share one cached answer.

| Route | Upstream | Cache |
|---|---|---|
| `GET /v1/tago/<Service>/<operation>` | 국토교통부 TAGO `apis.data.go.kr/1613000` (13 operations) | arrivals/locations 15 s, stops/routes 1 day, city codes 7 days; nearby-stop lookups (user coordinates) never cached |
| `GET /v1/seoul/<group>/<operation>` | 서울 버스 `ws.bus.go.kr/api/rest`, over http (8 operations) | arrivals/positions 15 s, stations/routes 1 day; getStationByPos never cached |

Only the operations in `ROUTES` (`src/index.js`) pass; anything else is 404.
Responses are the upstream JSON unchanged. Refusals: 429 (60/min per IP),
503 (daily cap per upstream service, `wrangler.toml` vars), 502 (upstream key,
quota or service error; never cached).

One data.go.kr account key covers both providers once all eight APIs are
approved for that account (TAGO 버스도착/위치/정류소/노선, 서울 정류소/노선/도착/위치).

## Run locally

```sh
cd relay && npm install
# .dev.vars (git-ignored): DATA_GO_KR_KEY=<일반 인증키 (Decoding)>
npx wrangler dev --port 8787
npm test
```

## Deploy (free plan)

```sh
npx wrangler login                      # once, opens the browser
npx wrangler secret put DATA_GO_KR_KEY
npx wrangler deploy                     # prints https://busonda-relay.<account>.workers.dev
```

If the printed URL differs, update `BusRelay.baseURL`
(`Modules/BusAPI/Sources/Utilities/BusRelay.swift`).
