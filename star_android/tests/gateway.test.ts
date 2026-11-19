// SPDX-License-Identifier: AGPL-3.0-or-later
import {test} from 'node:test';
import assert from 'node:assert/strict';
import {StarGateway, SocketLike} from '../src/gateway';
class FakeSocket implements SocketLike {
  readyState = 1; onmessage: SocketLike['onmessage'] = null; onclose: SocketLike['onclose'] = null; onerror: SocketLike['onerror'] = null;
  sent: any[] = []; closed = false;
  send(value: string) {this.sent.push(JSON.parse(value));}
  close() {this.closed = true;}
  receive(packet: any) {this.onmessage?.({data: JSON.stringify(packet)});}
}
test('gateway identifies after HELLO, uses Star subscriptions and dispatches messages', () => {
  const socket = new FakeSocket(); const events: string[] = []; const status: string[] = []; let address = '';
  const gateway = new StarGateway('wss://gateway.example', 'fixture-token', type => events.push(type), value => status.push(value), url => {address = url; return socket;});
  try {
    gateway.selectGuild('123'); gateway.connect();
    assert.equal(new URL(address).searchParams.get('v'), '1'); assert.equal(new URL(address).searchParams.get('compress'), 'none');
    assert.equal(socket.sent.length, 0);
    socket.receive({op:10, d:{heartbeat_interval:45000}});
    assert.equal(socket.sent[0].op, 2); assert.equal(socket.sent[0].d.token, 'fixture-token'); assert.equal(socket.sent[0].d.properties.os, 'Android');
    socket.receive({op:0, t:'READY', s:1, d:{session_id:'fixture-session'}});
    assert.equal(socket.sent[1].op, 14); assert.deepEqual(socket.sent[1].d, {subscriptions:{'123':{active:true,sync:true}}});
    socket.receive({op:0, t:'MESSAGE_CREATE', s:2, d:{channel_id:'456'}});
    socket.receive({op:1}); assert.deepEqual(socket.sent.at(-1), {op:1,d:2});
    gateway.selectGuild('789'); assert.deepEqual(socket.sent.at(-1).d, {subscriptions:{'123':{active:false}, '789':{active:true,sync:true}}});
    assert.deepEqual(events, ['READY','MESSAGE_CREATE']); assert.ok(status.includes('online'));
  } finally {gateway.stop();}
  assert.ok(socket.closed);
});
test('invalid token closes the connection instead of retrying indefinitely', () => {
  const socket = new FakeSocket(); let state = '';
  const gateway = new StarGateway('wss://gateway.example', 'fixture', () => {}, value => {state = value;}, () => socket);
  gateway.connect(); socket.onclose?.({code:4004}); assert.equal(state, 'sessão inválida'); gateway.stop();
});
