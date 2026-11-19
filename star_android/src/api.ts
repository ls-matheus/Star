// SPDX-License-Identifier: AGPL-3.0-or-later
// Reuse the web client's actual route definitions, not a second hardcoded API.
import {Endpoints} from '../../star_app/src/features/app/constants/Endpoints';
export {Endpoints};
export interface User {id: string; username: string; global_name?: string | null; avatar?: string | null}
export interface Guild {id: string; name: string; unavailable?: boolean}
export interface Channel {id: string; guild_id?: string; name?: string; type: number; recipients?: User[]; position?: number}
export interface Message {id: string; channel_id: string; content: string; author: User; timestamp: string; edited_timestamp?: string | null; attachments?: {id: string; filename: string}[]}
export interface LoginResult {token?: string; user_id?: string; mfa?: boolean; ticket?: string; totp?: boolean; ip_authorization_required?: boolean}
export interface Session {api: string; token: string}
export class ApiError extends Error {
  constructor(public status: number, public code: string, message: string, public retryAfter = 0) {super(message);}
}
export function normalizeApi(input: string): string {
  let url: URL;
  try {url = new URL(input.trim());} catch {throw new Error('Informe uma URL HTTPS válida para a API do Star.');}
  if (url.protocol !== 'https:' || url.username || url.password || url.search || url.hash) {
    throw new Error('Use HTTPS, sem credenciais, parâmetros ou fragmentos na URL.');
  }
  url.pathname = url.pathname.replace(/\/+$/, '') || '/api';
  return url.toString().replace(/\/$/, '');
}
export class StarApi {
  readonly base: string;
  private blockedUntil = 0;
  constructor(base: string, readonly token = '', private transport: typeof fetch = fetch) {this.base = normalizeApi(base);}
  async request<T>(path: string, method = 'GET', body?: unknown): Promise<T> {
    if (!path.startsWith('/') || path.startsWith('//')) throw new Error('Rota inválida.');
    if (Date.now() < this.blockedUntil) throw new ApiError(429, 'RATE_LIMITED', 'Aguarde antes de tentar novamente.', Math.ceil((this.blockedUntil - Date.now()) / 1000));
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 20000);
    try {
      const response = await this.transport(this.base + path, {
        method, redirect: 'error', signal: controller.signal,
        headers: {'Accept': 'application/json', 'Accept-Language': 'pt-BR',
          ...(body === undefined ? {} : {'Content-Type': 'application/json'}),
          ...(this.token ? {Authorization: this.token} : {})},
        ...(body === undefined ? {} : {body: JSON.stringify(body)}),
      });
      const text = await response.text();
      let data: any;
      try {data = text ? JSON.parse(text) : null;} catch {throw new ApiError(response.status, 'INVALID_RESPONSE', 'A URL não retornou JSON da API do Star. Confira o endereço.');}
      if (!response.ok) {
        const retry = Number(response.headers.get('Retry-After') || data?.retry_after || 0);
        if (response.status === 429) this.blockedUntil = Date.now() + Math.max(1, retry || 5) * 1000;
        const code = String(data?.code || 'API_ERROR');
        const message = response.status === 401 ? 'Sessão expirada ou credenciais inválidas.' :
          response.status === 403 ? 'Acesso negado. Confira permissões, verificação de IP ou restrições da conta.' :
          response.status === 429 ? `Limite de solicitações. Aguarde ${Math.max(1, retry || 5)} segundos.` :
          `A API recusou a solicitação (${response.status}; ${code}).`;
        // Never log payloads: auth errors can contain tickets or account data.
        throw new ApiError(response.status, code, message, retry);
      }
      return data as T;
    } catch (e) {
      if (e instanceof ApiError) throw e;
      throw new Error('Não foi possível conectar à API. Confira HTTPS, rede e disponibilidade do servidor.');
    } finally {clearTimeout(timeout);}
  }
  login(login: string, password: string) {return this.request<LoginResult>(Endpoints.AUTH_LOGIN, 'POST', {login, password});}
  totp(ticket: string, code: string) {return this.request<LoginResult>(Endpoints.AUTH_LOGIN_MFA_TOTP, 'POST', {ticket, code});}
  me() {return this.request<User>(Endpoints.USER_ME);}
  guilds() {return this.request<Guild[]>(Endpoints.USER_GUILDS_LIST + '?limit=100');}
  channels(guild?: string) {return this.request<Channel[]>(guild ? Endpoints.GUILD_CHANNELS(guild) : Endpoints.USER_CHANNELS);}
  messages(channel: string, before?: string) {
    return this.request<Message[]>(Endpoints.CHANNEL_MESSAGES(channel) + '?limit=50' + (before ? `&before=${encodeURIComponent(before)}` : ''));
  }
  send(channel: string, content: string, nonce: string) {
    return this.request<Message>(Endpoints.CHANNEL_MESSAGES(channel), 'POST', {content, nonce, allowed_mentions: {parse: []}});
  }
  logout() {return this.request(Endpoints.AUTH_LOGOUT, 'POST', {});}
  async gateway(): Promise<string> {
    const doc = await this.request<{endpoints?: {gateway?: string}}>('/.well-known/star');
    const url = new URL(doc.endpoints?.gateway || '');
    if (url.protocol !== 'wss:' || url.username || url.password) throw new Error('A instância não informou um gateway WSS válido.');
    return url.toString();
  }
}
export function mergeMessages(current: Message[], incoming: Message[]): Message[] {
  const map = new Map(current.map(m => [m.id, m]));
  for (const m of incoming) map.set(m.id, {...map.get(m.id), ...m});
  return [...map.values()].sort((a, b) => a.id.length - b.id.length || a.id.localeCompare(b.id)).slice(-500);
}
