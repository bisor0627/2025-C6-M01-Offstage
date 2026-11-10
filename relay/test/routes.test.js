import assert from 'node:assert/strict';
import test from 'node:test';
import { cleanQuery, isAnswer, matchRoute, ROUTES } from '../src/index.js';

test('every app operation is routed', () => {
  assert.equal(Object.keys(ROUTES.tago).length, 13);
  assert.equal(Object.keys(ROUTES.seoul).length, 8);
  assert.equal(matchRoute('/v1/tago/ArvlInfoInqireService/getSttnAcctoArvlPrearngeInfoList').ttl, 15);
  assert.equal(matchRoute('/v1/seoul/stationinfo/getStationByUid').service, 'seoul-station');
});

test('unknown paths are refused', () => {
  assert.equal(matchRoute('/v1/tago/ArvlInfoInqireService/getEverything'), null);
  assert.equal(matchRoute('/v1/seoul/../../etc'), null);
  assert.equal(matchRoute('/v1/other/a/b'), null);
  assert.equal(matchRoute('/'), null);
});

test('query drops client keys, forces json, sorts', () => {
  const q = new URLSearchParams('serviceKey=leak&nodeId=X&cityCode=25&_type=xml');
  assert.equal(cleanQuery(q, 'tago'), '_type=json&cityCode=25&nodeId=X');
  const s = new URLSearchParams('ServiceKey=leak&arsId=01001&resultType=xml');
  assert.equal(cleanQuery(s, 'seoul'), 'arsId=01001&resultType=json');
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
