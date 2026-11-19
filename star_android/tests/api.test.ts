// SPDX-License-Identifier: AGPL-3.0-or-later
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {ApiError, Endpoints, StarApi, mergeMessages, normalizeApi, Message} from '../src/api';

test('HTTPS instance normalization rejects credentials, plaintext and query injection', () => {
  assert.equal(normalizeApi(' https://chat.example/ '), 'https://chat.example/api');
  assert.equal(normalizeApi('https://chat.example/api/v1/'), 'https://chat.example/api/v1');
  for (const value of ['http://chat.example', 'https://user:secret@chat.example', 'https://chat.example/api?x=1', 'https://chat.example/#x', 'broken']) assert.throws(() => normalizeApi(value));
});
test('login, MFA, channel and send requests use Star routes and session-token semantics', async () => {
  const calls: {url: string; init: RequestInit}[] = [];
  const transport: typeof fetch = async (url, init) => {calls.push({url: String(url), init: init!}); return new Response(JSON.stringify({token: 'fixture-session', id: '123'}));};
  const anonymous = new StarApi('https://chat.example/api', '', transport);
  await anonymous.login('alice', 'fixture-password'); await anonymous.totp('fixture-ticket', '000000');
  assert.equal(calls[0].url, `https://chat.example/api${Endpoints.AUTH_LOGIN}`);
  assert.deepEqual(JSON.parse(String(calls[0].init.body)), {login: 'alice', password: 'fixture-password'});
  assert.equal((calls[0].init.headers as any).Authorization, undefined);
  assert.equal(calls[1].url, `https://chat.example/api${Endpoints.AUTH_LOGIN_MFA_TOTP}`);
  const client = new StarApi('https://chat.example/api', 'fixture-session', transport);
  await client.channels('456'); await client.messages('789', '123'); await client.send('789', 'hello', '456789');
  assert.equal(calls[2].url, 'https://chat.example/api/guilds/456/channels');
  assert.equal((calls[2].init.headers as any).Authorization, 'fixture-session');
  assert.equal(calls[2].init.redirect, 'error');
  assert.equal(calls[3].url, 'https://chat.example/api/channels/789/messages?limit=50&before=123');
  assert.deepEqual(JSON.parse(String(calls[4].init.body)), {content: 'hello', nonce: '456789', allowed_mentions: {parse: []}});
  await assert.rejects(client.request('//other.example'), /Rota inválida/);
});
test('rate limits block immediate subsequent calls and never replay a POST', async () => {
  let calls = 0;
  const client = new StarApi('https://chat.example/api', '', async () => {calls++; return new Response('{"retry_after":3}', {status: 429});});
  await assert.rejects(client.send('1', 'hello', '1'), (e: ApiError) => e.status === 429 && e.retryAfter === 3);
  await assert.rejects(client.me(), (e: ApiError) => e.status === 429);
  assert.equal(calls, 1);
});
test('JSON errors, forbidden and expired sessions remain distinguishable', async () => {
  for (const status of [401, 403, 500]) {
    const client = new StarApi('https://chat.example/api', '', async () => new Response('{"code":"TEST"}', {status}));
    await assert.rejects(client.me(), (e: ApiError) => e.status === status && e.code === 'TEST');
  }
  const client = new StarApi('https://chat.example/api', '', async () => new Response('<html>not api</html>'));
  await assert.rejects(client.me(), (e: ApiError) => e.code === 'INVALID_RESPONSE');
});
test('gateway comes from Star discovery and must use WSS', async () => {
  const client = new StarApi('https://chat.example/api', '', async () => new Response('{"endpoints":{"gateway":"wss://gateway.example"}}'));
  assert.equal(await client.gateway(), 'wss://gateway.example/');
  const bad = new StarApi('https://chat.example/api', '', async () => new Response('{"endpoints":{"gateway":"ws://gateway.example"}}'));
  await assert.rejects(bad.gateway(), /WSS/);
});
test('message merge deduplicates REST/gateway delivery and orders snowflakes without precision loss', () => {
  const m = (id: string, content: string) => ({id, content, channel_id: '1', author: {id:'1', username:'test'}, timestamp: ''}) as Message;
  const result = mergeMessages([m('99999999999999999', 'old'), m('100000000000000000', 'new')], [m('99999999999999999', 'edited')]);
  assert.equal(result.length, 2); assert.equal(result[0].content, 'edited'); assert.equal(result[1].content, 'new');
});
