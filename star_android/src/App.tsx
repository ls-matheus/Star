// SPDX-License-Identifier: AGPL-3.0-or-later
import React, {useEffect, useMemo, useRef, useState} from 'react';
import {ActivityIndicator, Alert, AppState, BackHandler, FlatList, KeyboardAvoidingView, Pressable, ScrollView, StatusBar, StyleSheet, Text, TextInput, View} from 'react-native';
import {SafeAreaProvider, SafeAreaView} from 'react-native-safe-area-context';
import * as SecureStore from 'expo-secure-store';
import {DEFAULT_ACCENT_COLOR} from '../../packages/constants/src/AppConstants';
import {ChannelTypes} from '../../packages/constants/src/ChannelConstants';
import {ApiError, Channel, Guild, LoginResult, Message, Session, StarApi, User, mergeMessages, normalizeApi} from './api';
import {StarGateway} from './gateway';

const KEY = 'star.android.session.v1';
// Same neutralDark hue (258) and brand accent as star_app's ColorSystemPalette.
const colors = {brand: DEFAULT_ACCENT_COLOR, bg: '#111015', panel: '#1b1923', border: '#35313f', text: '#f4f3f8', muted: '#bbb5c9', error: '#ffadb2'};
const supported = new Set<number>([ChannelTypes.GUILD_TEXT, ChannelTypes.GUILD_ANNOUNCEMENT, ChannelTypes.DM, ChannelTypes.GROUP_DM, ChannelTypes.DM_PERSONAL_NOTES]);
const channelName = (c: Channel) => c.name || c.recipients?.map(u => u.global_name || u.username).join(', ') || (c.type === ChannelTypes.DM_PERSONAL_NOTES ? 'Notas pessoais' : 'Conversa');
const describe = (e: unknown) => e instanceof Error ? e.message : 'Não foi possível concluir a operação.';
function Button({title, onPress, disabled = false, secondary = false}: {title: string; onPress: () => void; disabled?: boolean; secondary?: boolean}) {
  return <Pressable accessibilityRole="button" accessibilityLabel={title} disabled={disabled} onPress={onPress} style={({pressed}) => [s.button, secondary && s.secondary, (disabled || pressed) && {opacity: 0.5}]}><Text style={s.buttonText}>{title}</Text></Pressable>;
}
function AppContent() {
  const [booting, setBooting] = useState(true);
  const [session, setSession] = useState<Session | null>(null);
  const [base, setBase] = useState(''); const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState(''); const [ticket, setTicket] = useState(''); const [code, setCode] = useState('');
  const [busy, setBusy] = useState(false); const [sending, setSending] = useState(false); const [error, setError] = useState('');
  const [me, setMe] = useState<User | null>(null); const [guilds, setGuilds] = useState<Guild[]>([]);
  const [guild, setGuild] = useState<Guild | null>(null); const [view, setView] = useState<'home' | 'channels' | 'chat'>('home');
  const [channels, setChannels] = useState<Channel[]>([]); const [channel, setChannel] = useState<Channel | null>(null);
  const [messages, setMessages] = useState<Message[]>([]); const [draft, setDraft] = useState(''); const [more, setMore] = useState(false);
  const [connection, setConnection] = useState('desconectado');
  const gateway = useRef<StarGateway | null>(null); const channelRef = useRef<Channel | null>(null);
  const generation = useRef(0); const list = useRef<FlatList<Message>>(null); const pending = useRef<{content: string; nonce: string} | null>(null);
  const api = useMemo(() => session ? new StarApi(session.api, session.token) : null, [session]);

  useEffect(() => {
    let live = true;
    SecureStore.getItemAsync(KEY).then(value => {
      if (!live || !value) return;
      const saved = JSON.parse(value);
      if (typeof saved.token === 'string' && saved.token && typeof saved.api === 'string') {setBase(normalizeApi(saved.api)); setSession({api: normalizeApi(saved.api), token: saved.token});}
    }).catch(() => {if (live) setError('Não foi possível restaurar a sessão. Entre novamente.');}).finally(() => {if (live) setBooting(false);});
    return () => {live = false;};
  }, []);
  async function clearSession() {
    generation.current++; gateway.current?.stop(); gateway.current = null;
    setSession(null); setMe(null); setGuilds([]); setChannels([]); setMessages([]); setChannel(null); channelRef.current = null;
    setGuild(null); setView('home'); setDraft(''); setPassword(''); setTicket(''); setCode(''); pending.current = null;
    try {await SecureStore.deleteItemAsync(KEY);} catch {setError('Não foi possível remover a sessão do armazenamento seguro. Limpe os dados do app nas configurações do Android.');}
  }
  async function fail(e: unknown) {
    if (e instanceof ApiError && e.status === 401 && session) await clearSession();
    setError(describe(e));
  }
  async function acceptLogin(result: LoginResult, endpoint: string) {
    if (result.mfa && result.ticket) {
      if (!result.totp) throw new Error('Esta conta exige um método de MFA ainda não implementado no Android.');
      setTicket(result.ticket); setPassword(''); setCode(''); return;
    }
    if (result.ip_authorization_required) throw new Error('Autorize este dispositivo pelo e-mail da instância e tente novamente. O fluxo de autorização de IP ainda não foi migrado.');
    if (!result.token) throw new Error('A instância solicitou uma etapa de autenticação ainda não suportada.');
    const next = {api: endpoint, token: result.token};
    await SecureStore.setItemAsync(KEY, JSON.stringify(next));
    setPassword(''); setCode(''); setTicket(''); setSession(next);
  }
  async function login() {
    setBusy(true); setError('');
    try {
      const client = new StarApi(base); setBase(client.base);
      const result = ticket ? await client.totp(ticket, code.trim()) : await client.login(identifier.trim(), password);
      await acceptLogin(result, client.base);
    } catch (e) {setError(describe(e));} finally {setBusy(false);}
  }
  async function refreshHome(client = api) {
    if (!client) return;
    const [user, groups] = await Promise.all([client.me(), client.guilds()]);
    setMe(user); setGuilds(groups);
  }
  useEffect(() => {
    if (!api) return;
    let live = true;
    setBusy(true); setError('');
    Promise.all([api.me(), api.guilds()]).then(([user, groups]) => {if (live) {setMe(user); setGuilds(groups);}})
      .catch(e => {if (live) void fail(e);}).finally(() => {if (live) setBusy(false);});
    const connect = async () => {
      try {
        const url = await api.gateway(); if (!live) return;
        gateway.current?.stop();
        const ws = new StarGateway(url, api.token, (type, data) => {
          if (!live) return;
          const selected = channelRef.current;
          if (selected && data?.channel_id === selected.id) {
            if (type === 'MESSAGE_CREATE' || type === 'MESSAGE_UPDATE') setMessages(items => {
              if (type === 'MESSAGE_UPDATE' && !items.some(m => m.id === data.id)) return items;
              return mergeMessages(items, [data]);
            });
            if (type === 'MESSAGE_DELETE') setMessages(items => items.filter(m => m.id !== data.id));
            if (type === 'MESSAGE_DELETE_BULK') setMessages(items => items.filter(m => !data.ids?.includes(m.id)));
          }
          if (type === 'READY' || type === 'RESUMED') {
            if (selected) void loadMessages(selected, false, api);
          }
          if (type === 'CHANNEL_DELETE' && selected?.id === data?.id) {generation.current++; channelRef.current = null; setChannel(null); setView('home'); setMessages([]); setError('Este canal não está mais disponível.');}
        }, value => {if (live) setConnection(value);});
        gateway.current = ws; ws.selectGuild(channelRef.current?.guild_id); ws.connect();
      } catch {if (live) setConnection('gateway indisponível — use Atualizar');}
    };
    void connect();
    const subscription = AppState.addEventListener('change', state => {
      if (state === 'active') {void connect(); if (channelRef.current) void loadMessages(channelRef.current, false, api);}
      else {gateway.current?.stop(); gateway.current = null;}
    });
    return () => {live = false; subscription.remove(); gateway.current?.stop(); gateway.current = null;};
  }, [api]);

  function back() {
    if (sending) return;
    generation.current++; setError('');
    if (view === 'chat') {setView('channels'); setChannel(null); channelRef.current = null; setMessages([]); setDraft(''); pending.current = null;}
    else {setView('home'); setGuild(null); gateway.current?.selectGuild();}
  }
  useEffect(() => {const sub = BackHandler.addEventListener('hardwareBackPress', () => {if (session && view !== 'home') {back(); return true;} return false;}); return () => sub.remove();}, [view, session, sending]);
  async function openChannels(group: Guild | null) {
    if (!api) return;
    const version = ++generation.current;
    setGuild(group); setChannels([]); setView('channels'); setBusy(true); setError(''); gateway.current?.selectGuild(group?.id);
    try {const result = await api.channels(group?.id); if (generation.current === version) setChannels(result.filter(c => supported.has(c.type)).sort((a,b) => (a.position || 0) - (b.position || 0)));}
    catch (e) {if (generation.current === version) await fail(e);} finally {setBusy(false);}
  }
  async function loadMessages(selected: Channel, older = false, client = api) {
    if (!client) return;
    const version = generation.current;
    setBusy(true);
    try {
      const batch = await client.messages(selected.id, older ? messages[0]?.id : undefined);
      if (version === generation.current && channelRef.current?.id === selected.id) {
        setMessages(items => older ? mergeMessages(batch, items) : mergeMessages([], batch)); setMore(batch.length === 50);
      }
    } catch (e) {if (version === generation.current) await fail(e);} finally {if (version === generation.current) setBusy(false);}
  }
  function openChannel(selected: Channel) {
    generation.current++; channelRef.current = selected; setChannel(selected); setMessages([]); setDraft(''); setMore(false); setError(''); pending.current = null; setView('chat');
    gateway.current?.selectGuild(selected.guild_id || guild?.id); void loadMessages(selected);
  }
  async function send() {
    const content = draft.trim(); if (!api || !channel || !content || sending) return;
    setSending(true); setError('');
    if (pending.current?.content !== content) pending.current = {content, nonce: `${Date.now()}${Math.floor(Math.random() * 1e9)}`};
    const version = generation.current;
    try {
      const message = await api.send(channel.id, content, pending.current.nonce);
      if (version === generation.current) {setMessages(items => mergeMessages(items, [message])); setDraft(''); pending.current = null; setTimeout(() => list.current?.scrollToEnd({animated: true}), 100);}
    } catch (e) {if (version === generation.current) await fail(e);} finally {setSending(false);}
  }
  function logout() {Alert.alert('Sair do Star?', 'A sessão será encerrada neste dispositivo.', [{text: 'Cancelar', style: 'cancel'}, {text: 'Sair', onPress: () => {void (async () => {let revoked = true; try {await api?.logout();} catch {revoked = false;} await clearSession(); if (!revoked) setError('Sessão local removida. O servidor estava indisponível; revogue a sessão nas configurações da sua conta.');})();}}]);}
  function about() {Alert.alert('Star Android • 0.1.0', 'Base nativa em React Native, integrada às APIs do repositório ls-matheus/Star.\n\nDisponível: login com senha/TOTP, comunidades (primeiras 100), conversas existentes, canais de texto e mensagens (até 500 carregadas).\n\nAinda faltam: cadastro, SSO/passkeys/CAPTCHA, fluxo de IP, anexos, Markdown, edição, reações, notificações push, voz/vídeo, fóruns, administração e paridade visual completa.\n\nCódigo AGPL-3.0-or-later. Arquitetura e atribuições preservadas no repositório.');}

  if (booting) return <View style={s.center}><ActivityIndicator color={colors.brand}/><Text style={s.muted}>Abrindo Star…</Text></View>;
  return <SafeAreaView style={s.safe} edges={['top', 'bottom']}><StatusBar barStyle="light-content" backgroundColor={colors.bg}/>
    <View style={s.header}>
      {session && view !== 'home' ? <Button title="‹ Voltar" onPress={back} secondary disabled={sending}/> : <Text style={s.mark}>★</Text>}
      <View style={s.grow}><Text style={s.title} numberOfLines={1}>{view === 'chat' && channel ? `# ${channelName(channel)}` : 'Star'}</Text><Text style={s.caption}>{session ? connection : 'Android nativo • versão inicial'}</Text></View>
      <Pressable accessibilityRole="button" accessibilityLabel="Sobre o Star Android" onPress={about}><Text style={s.info}>ⓘ</Text></Pressable>
    </View>
    {error ? <View style={s.error} accessibilityRole="alert"><Text style={{color: colors.error}}>{error}</Text><Pressable accessibilityRole="button" onPress={() => setError('')}><Text style={s.caption}>Fechar aviso</Text></Pressable></View> : null}
    {!session ? <KeyboardAvoidingView style={s.grow} behavior="padding"><ScrollView keyboardShouldPersistTaps="handled" contentContainerStyle={s.login}>
      <Text style={s.hero}>{ticket ? 'Verificação em duas etapas' : 'Seu espaço.\nSuas conversas.'}</Text>
      <Text style={s.muted}>Conecte à sua instância Star. Use a URL HTTPS da API publicada pelo administrador.</Text>
      <Text style={s.label}>URL da API</Text><TextInput accessibilityLabel="URL da API" editable={!busy && !ticket} autoCapitalize="none" autoCorrect={false} keyboardType="url" placeholder="https://seu-servidor/api" placeholderTextColor={colors.muted} value={base} onChangeText={setBase} style={s.input}/>
      {ticket ? <><Text style={s.label}>Código do autenticador</Text><TextInput accessibilityLabel="Código do autenticador" autoComplete="one-time-code" keyboardType="number-pad" value={code} onChangeText={setCode} maxLength={10} style={s.input}/></> : <>
        <Text style={s.label}>E-mail ou usuário</Text><TextInput accessibilityLabel="E-mail ou usuário" autoCapitalize="none" autoCorrect={false} autoComplete="username" value={identifier} onChangeText={setIdentifier} style={s.input}/>
        <Text style={s.label}>Senha</Text><TextInput accessibilityLabel="Senha" secureTextEntry autoComplete="current-password" value={password} onChangeText={setPassword} style={s.input}/>
      </>}
      <Button title={busy ? 'Conectando…' : ticket ? 'Verificar e entrar' : 'Entrar'} onPress={() => void login()} disabled={busy || !base || (ticket ? !code.trim() : !identifier.trim() || !password)}/>
      {ticket ? <Button title="Voltar ao login" secondary disabled={busy} onPress={() => {setTicket(''); setCode('');}}/> : null}
      <Text style={s.caption}>É necessária uma conta existente. Cadastro, SSO, passkeys, CAPTCHA e autorização de IP ainda não estão disponíveis nesta versão.</Text>
    </ScrollView></KeyboardAvoidingView> : view === 'home' ? <ScrollView contentContainerStyle={s.content}>
      <Text style={s.hero}>Olá, {me?.global_name || me?.username || 'você'}.</Text><Text style={s.muted}>Comunidades e conversas</Text>
      <Button title="Mensagens diretas" onPress={() => void openChannels(null)}/>
      {busy && <ActivityIndicator color={colors.brand}/>}
      {guilds.map(g => <Pressable accessibilityRole="button" key={g.id} disabled={g.unavailable} onPress={() => void openChannels(g)} style={s.row}><View style={s.avatar}><Text style={s.buttonText}>{g.name?.slice(0, 2).toUpperCase()}</Text></View><Text style={s.rowTitle}>{g.name}{g.unavailable ? ' (indisponível)' : ''}</Text><Text style={s.muted}>›</Text></Pressable>)}
      {!busy && guilds.length === 0 && <Text style={s.muted}>Nenhuma comunidade carregada. Você pode abrir suas conversas diretas ou tentar atualizar.</Text>}
      <Button title="Atualizar comunidades" secondary disabled={busy} onPress={() => {setBusy(true); void refreshHome().catch(fail).finally(() => setBusy(false));}}/>
      <Button title="Sair da conta" secondary onPress={logout}/><Text style={s.caption}>{session.api}</Text>
    </ScrollView> : view === 'channels' ? <View style={s.grow}><View style={s.content}><Text style={s.section}>{guild?.name || 'Mensagens diretas'}</Text><Text style={s.caption}>Canais de texto e conversas existentes</Text><Button title="Atualizar canais" secondary disabled={busy} onPress={() => void openChannels(guild)}/></View>
      {busy && <ActivityIndicator color={colors.brand}/>}
      <FlatList data={channels} keyExtractor={c => c.id} contentContainerStyle={s.content} ListEmptyComponent={!busy ? <Text style={s.muted}>Nenhum canal de texto disponível nesta seleção.</Text> : null} renderItem={({item}) => <Pressable accessibilityRole="button" onPress={() => openChannel(item)} style={s.row}><Text style={s.hash}>#</Text><Text style={s.rowTitle}>{channelName(item)}</Text><Text style={s.muted}>›</Text></Pressable>}/>
    </View> : <KeyboardAvoidingView behavior="padding" style={s.grow}>
      <View style={s.toolbar}><Button title="Atualizar" secondary disabled={busy} onPress={() => {if (channel) void loadMessages(channel);}}/>{busy && <ActivityIndicator color={colors.brand}/>}</View>
      <FlatList ref={list} data={messages} keyExtractor={m => m.id} contentContainerStyle={s.content} keyboardShouldPersistTaps="handled"
        ListHeaderComponent={more ? <Button title="Carregar anteriores" secondary disabled={busy} onPress={() => {if (channel) void loadMessages(channel, true);}}/> : null}
        ListEmptyComponent={!busy ? <Text style={s.muted}>Nenhuma mensagem carregada.</Text> : null}
        renderItem={({item}) => <View style={s.message}><View style={s.messageHead}><Text style={s.author}>{item.author?.global_name || item.author?.username || 'Usuário'}</Text><Text style={s.caption}>{item.timestamp ? new Date(item.timestamp).toLocaleTimeString('pt-BR', {hour: '2-digit', minute: '2-digit'}) : ''}{item.edited_timestamp ? ' • editada' : ''}</Text></View><Text selectable style={s.messageText}>{item.content || (item.attachments?.length ? '' : '[Mensagem sem texto]')}</Text>{item.attachments?.map(a => <Text key={a.id} style={s.caption}>Anexo: {a.filename} (visualização pendente)</Text>)}</View>}/>
      <View style={s.composer}><TextInput accessibilityLabel="Mensagem" multiline editable={!sending} maxLength={2000} value={draft} onChangeText={setDraft} placeholder="Escreva uma mensagem…" placeholderTextColor={colors.muted} style={[s.input, s.composeInput]}/><Button title={sending ? '…' : 'Enviar'} disabled={sending || !draft.trim()} onPress={() => void send()}/></View>
    </KeyboardAvoidingView>}
  </SafeAreaView>;
}
export default function App() {return <SafeAreaProvider><AppContent/></SafeAreaProvider>;}
const s = StyleSheet.create({
  safe: {flex: 1, backgroundColor: colors.bg}, grow: {flex: 1}, center: {flex: 1, backgroundColor: colors.bg, justifyContent: 'center', alignItems: 'center', gap: 14},
  header: {flexDirection: 'row', alignItems: 'center', gap: 14, paddingHorizontal: 18, paddingVertical: 14, borderBottomWidth: 1, borderBottomColor: colors.border},
  mark: {fontSize: 34, color: '#fff', backgroundColor: colors.brand, borderRadius: 16, width: 54, height: 54, textAlign: 'center', textAlignVertical: 'center'},
  title: {fontSize: 23, fontWeight: '800', color: colors.text}, caption: {fontSize: 12, lineHeight: 18, color: colors.muted}, muted: {color: colors.muted, fontSize: 15, lineHeight: 23},
  info: {fontSize: 26, color: colors.muted, padding: 8}, login: {padding: 24, gap: 12}, hero: {color: colors.text, fontSize: 30, lineHeight: 37, fontWeight: '800', marginVertical: 16},
  label: {color: colors.text, fontWeight: '600', marginTop: 8}, input: {backgroundColor: colors.panel, color: colors.text, borderColor: colors.border, borderWidth: 1, borderRadius: 12, padding: 14, fontSize: 16},
  button: {backgroundColor: colors.brand, borderRadius: 12, paddingVertical: 13, paddingHorizontal: 16, alignItems: 'center', justifyContent: 'center', minHeight: 46}, secondary: {backgroundColor: colors.panel, borderWidth: 1, borderColor: colors.border}, buttonText: {color: '#fff', fontSize: 15, fontWeight: '700'},
  error: {padding: 14, gap: 6, backgroundColor: '#341c26'}, content: {padding: 18, gap: 12}, row: {flexDirection: 'row', alignItems: 'center', gap: 12, padding: 16, borderRadius: 14, backgroundColor: colors.panel},
  avatar: {width: 40, height: 40, borderRadius: 14, backgroundColor: colors.brand, justifyContent: 'center', alignItems: 'center'}, rowTitle: {color: colors.text, fontSize: 16, fontWeight: '600', flex: 1}, hash: {fontSize: 28, color: colors.muted}, section: {fontSize: 22, fontWeight: '700', color: colors.text},
  toolbar: {paddingHorizontal: 18, paddingTop: 10, flexDirection: 'row', alignItems: 'center', gap: 16}, message: {paddingVertical: 10, gap: 6}, messageHead: {flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 10}, author: {color: colors.text, fontWeight: '700', fontSize: 15}, messageText: {color: colors.text, fontSize: 16, lineHeight: 24},
  composer: {padding: 12, gap: 10, flexDirection: 'row', alignItems: 'flex-end', borderTopWidth: 1, borderTopColor: colors.border}, composeInput: {flex: 1, maxHeight: 140, margin: 0},
});
