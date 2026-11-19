// SPDX-License-Identifier: AGPL-3.0-or-later
import {GatewayOpcodes as Op} from '../../packages/constants/src/GatewayConstants';
import {DEFAULT_API_VERSION} from '../../packages/constants/src/AppConstants';
type Packet = {op: number; s?: number; t?: string; d?: any};
export interface SocketLike {
  readyState: number; send(value: string): void; close(code?: number): void;
  onmessage: ((e: {data: any}) => void) | null;
  onclose: ((e: {code: number}) => void) | null;
  onerror: ((e: any) => void) | null;
}
export type GatewayStatus = 'conectando' | 'online' | 'reconectando' | 'sessão inválida' | 'desconectado';
export class StarGateway {
  private socket?: SocketLike;
  private heartbeat?: ReturnType<typeof setInterval>;
  private retry?: ReturnType<typeof setTimeout>;
  private helloDeadline?: ReturnType<typeof setTimeout>;
  private seq: number | null = null;
  private sessionId: string | null = null;
  private ack = true;
  private stopped = false;
  private attempt = 0;
  private activeGuild?: string;
  private ready = false;
  constructor(private url: string, private token: string,
    private dispatch: (type: string, data: any) => void,
    private status: (value: GatewayStatus) => void,
    private factory: (url: string) => SocketLike = url => new WebSocket(url) as unknown as SocketLike) {}
  connect() {
    if (this.stopped || this.socket) return;
    this.status(this.attempt ? 'reconectando' : 'conectando');
    const url = new URL(this.url);
    url.searchParams.set('v', String(DEFAULT_API_VERSION));
    url.searchParams.set('encoding', 'json'); url.searchParams.set('compress', 'none');
    let socket: SocketLike;
    try {socket = this.factory(url.toString());} catch {this.schedule(); return;}
    this.socket = socket;
    this.helloDeadline = setTimeout(() => this.reconnect(), 25000);
    socket.onmessage = event => {
      if (this.socket !== socket || this.stopped) return;
      try {this.receive(JSON.parse(String(event.data)));} catch {this.reconnect();}
    };
    socket.onerror = () => {if (this.socket === socket) this.reconnect();};
    socket.onclose = event => {
      if (this.socket !== socket || this.stopped) return;
      this.clearSocket();
      if ([4004, 4010, 4011, 4012].includes(event.code)) {this.stopped = true; this.status('sessão inválida'); return;}
      if ([4007, 4009].includes(event.code)) {this.sessionId = null; this.seq = null;}
      this.schedule();
    };
  }
  private send(op: number, d: unknown) {if (this.socket?.readyState === 1) this.socket.send(JSON.stringify({op, d}));}
  private receive(p: Packet) {
    if (typeof p.s === 'number') this.seq = p.s;
    if (p.op === Op.HELLO) {
      clearTimeout(this.helloDeadline);
      const interval = Number(p.d?.heartbeat_interval);
      if (!Number.isFinite(interval) || interval < 1000) {this.reconnect(); return;}
      clearInterval(this.heartbeat); this.ack = true;
      this.heartbeat = setInterval(() => {
        if (!this.ack) {this.reconnect(); return;}
        this.ack = false; this.send(Op.HEARTBEAT, this.seq);
      }, interval);
      if (this.sessionId && this.seq !== null) this.send(Op.RESUME, {token: this.token, session_id: this.sessionId, seq: this.seq});
      else this.send(Op.IDENTIFY, {token: this.token, properties: {
        os: 'Android', browser: 'Star Android', device: 'mobile', locale: 'pt-BR',
        user_agent: 'StarAndroid/0.1.0', browser_version: '0.1.0', os_version: '', build_version: '0.1.0',
      }, presence: {status: 'online', afk: false, mobile: true}, flags: 0});
    } else if (p.op === Op.HEARTBEAT_ACK) this.ack = true;
    else if (p.op === Op.HEARTBEAT) this.send(Op.HEARTBEAT, this.seq);
    else if (p.op === Op.RECONNECT) this.reconnect();
    else if (p.op === Op.INVALID_SESSION) {
      if (!p.d) {this.sessionId = null; this.seq = null;}
      this.reconnect();
    } else if (p.op === Op.DISPATCH && p.t) {
      if (p.t === 'READY' || p.t === 'RESUMED') {
        if (p.t === 'READY') this.sessionId = p.d?.session_id ?? null;
        this.attempt = 0; this.ready = true; this.status('online'); this.selectGuild(this.activeGuild);
      }
      this.dispatch(p.t, p.d);
    }
  }
  selectGuild(guild?: string) {
    const previous = this.activeGuild; this.activeGuild = guild;
    if (!this.ready) return;
    const subscriptions: Record<string, unknown> = {};
    if (previous && previous !== guild) subscriptions[previous] = {active: false};
    if (guild) subscriptions[guild] = {active: true, sync: true};
    if (Object.keys(subscriptions).length) this.send(Op.LAZY_REQUEST, {subscriptions});
  }
  private clearSocket() {
    clearInterval(this.heartbeat); clearTimeout(this.helloDeadline);
    const socket = this.socket; this.socket = undefined; this.ready = false;
    if (socket) {socket.onclose = null; socket.onmessage = null; socket.onerror = null; socket.close(1000);}
  }
  private reconnect() {this.clearSocket(); this.schedule();}
  private schedule() {
    if (this.stopped || this.retry) return;
    this.status('reconectando');
    this.retry = setTimeout(() => {this.retry = undefined; this.connect();}, Math.min(30000, 1000 * 2 ** Math.min(this.attempt++, 5)) + Math.random() * 500);
  }
  stop() {this.stopped = true; clearTimeout(this.retry); this.retry = undefined; this.clearSocket(); this.status('desconectado');}
}
