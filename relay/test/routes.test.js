import assert from 'node:assert/strict';
import test from 'node:test';
import { cleanQuery, ipHash, isAnswer, matchRoute, ROUTES } from '../src/index.js';

test('every app operation is routed', () => {
  assert.equal(Object.keys(ROUTES.tago).length, 13);
  assert.equal(Object.keys(ROUTES.seoul).length, 9);
  assert.equal(matchRoute('/v1/tago/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList').ttl, 10);
  assert.equal(matchRoute('/v1/seoul/busRouteInfo/getRouteInfo').service, 'seoul-route');
  assert.equal(matchRoute('/v1/seoul/stationinfo/getStationByUid').service, 'seoul-station');
});

test('nearby-stop lookups carry user coordinates and are never cached', () => {
  assert.equal(matchRoute('/v1/tago/BusSttnInfoInqireService/getCrdntPrxmtSttnList').ttl, 0);
  assert.equal(matchRoute('/v1/seoul/stationinfo/getStationByPos').ttl, 0);
});

test('unknown paths are refused', () => {
  assert.equal(matchRoute('/v1/tago/ArvlInfoInqireService/getEverything'), null);
  assert.equal(matchRoute('/v1/seoul/../../etc'), null);
  assert.equal(matchRoute('/v1/other/a/b'), null);
  assert.equal(matchRoute('/'), null);
});

test('query keeps only route params, forces json, sorts', () => {
  const arrivals = matchRoute('/v1/tago/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList');
  const q = new URLSearchParams('serviceKey=leak&nodeId=X&cityCode=25&_type=xml&bust=123');
  assert.equal(cleanQuery(q, arrivals), '_type=json&cityCode=25&nodeId=X');
  const uid = matchRoute('/v1/seoul/stationinfo/getStationByUid');
  const s = new URLSearchParams('ServiceKey=leak&arsId=01001&resultType=xml&x=1');
  assert.equal(cleanQuery(s, uid), 'arsId=01001&resultType=json');
});

test('every route declares its params', () => {
  for (const provider of Object.keys(ROUTES)) {
    for (const [path, route] of Object.entries(ROUTES[provider])) {
      assert.ok(Array.isArray(route.params), `${provider}/${path}`);
    }
  }
});

test('client hash hides the IP and changes daily', async () => {
  const a = await ipHash('203.0.113.7', '2026-11-12');
  assert.equal(a, await ipHash('203.0.113.7', '2026-11-12'));
  assert.notEqual(a, await ipHash('203.0.113.7', '2026-11-13'));
  assert.notEqual(a, await ipHash('203.0.113.8', '2026-11-12'));
  assert.match(a, /^[0-9a-f]{16}$/);
});

test('tago answers vs errors', () => {
  assert.ok(isAnswer('tago', '{"response":{"header":{"resultCode":"00"}}}'));
  assert.ok(isAnswer('tago', '{"response":{"header":{"resultCode":"03"}}}'));
  assert.ok(!isAnswer('tago', '{"OpenAPI_ServiceResponse":{"cmmMsgHeader":{"returnReasonCode":"30"}}}'));
  assert.ok(!isAnswer('tago', '<OpenAPI_ServiceResponse/>'));
});

test('seoul answers vs errors', () => {
  assert.ok(isAnswer('seoul', '{"msgHeader":{"headerCd":"0"}}'));
  assert.ok(isAnswer('seoul', '{"msgHeader":{"headerCd":"4"}}'));
  assert.ok(!isAnswer('seoul', '{"msgHeader":{"headerCd":"7"}}'));
  assert.ok(!isAnswer('seoul', '{"error":"Unauthorized","status":401}'));
});
