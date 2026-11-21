// SPDX-License-Identifier: AGPL-3.0-or-later
// Fully local development workspace: never calls the API or creates real auth credentials.
import {
	type DevCommunity,
	type DevMessage,
	type DevWorkspaceState,
	freshDevWorkspace,
	leaveDevSession,
	loadDevWorkspace,
	saveDevWorkspace,
} from '@app/features/dev_session/DevSessionState';
import StarLogo from '@app/media/images/star-logo-color.svg?react';
import {PencilSimpleIcon, PlusIcon, TrashIcon} from '@phosphor-icons/react';
import {type FormEvent, type KeyboardEvent, useEffect, useMemo, useState} from 'react';
import styles from './DevWorkspace.module.css';

type DialogKind =
	| 'create-community'
	| 'rename-community'
	| 'delete-community'
	| 'create-channel'
	| 'rename-channel'
	| 'delete-channel'
	| 'profile'
	| 'reset';

interface DevDialog {
	kind: DialogKind;
	targetId?: string;
}

const dialogTitles: Record<DialogKind, string> = {
	'create-community': 'Criar comunidade',
	'rename-community': 'Renomear comunidade',
	'delete-community': 'Excluir comunidade',
	'create-channel': 'Criar canal',
	'rename-channel': 'Editar canal',
	'delete-channel': 'Excluir canal',
	profile: 'Editar perfil Dev',
	reset: 'Limpar dados desta sessão',
};

function newId(): string {
	if (typeof crypto !== 'undefined' && typeof crypto.randomUUID === 'function') return crypto.randomUUID();
	return `dev-${Date.now()}-${Math.random().toString(36).slice(2)}`;
}

function formatTime(value: number): string {
	return new Intl.DateTimeFormat('pt-BR', {hour: '2-digit', minute: '2-digit'}).format(value);
}

function initials(value: string): string {
	return value.trim().slice(0, 2).toUpperCase() || 'DV';
}

export function DevWorkspace() {
	const [workspace, setWorkspace] = useState<DevWorkspaceState>(loadDevWorkspace);
	const [cacheAvailable, setCacheAvailable] = useState(true);
	const [search, setSearch] = useState('');
	const [dialog, setDialog] = useState<DevDialog | null>(null);
	const [dialogValue, setDialogValue] = useState('');
	const [dialogTopic, setDialogTopic] = useState('');
	const [editingId, setEditingId] = useState<string | null>(null);
	const [editingBody, setEditingBody] = useState('');

	// sessionStorage is per-tab and is removed when Dev mode is exited.
	useEffect(() => {
		setCacheAvailable(saveDevWorkspace(workspace));
	}, [workspace]);

	const community = useMemo(
		() => workspace.communities.find((entry) => entry.id === workspace.selectedCommunityId) ?? null,
		[workspace.communities, workspace.selectedCommunityId],
	);
	const channel = community?.channels.find((entry) => entry.id === workspace.selectedChannelId) ?? null;
	const currentMessages = useMemo(() => {
		const term = search.trim().toLocaleLowerCase('pt-BR');
		return workspace.messages.filter(
			(message) =>
				message.channelId === workspace.selectedChannelId &&
				(!term ||
					message.body.toLocaleLowerCase('pt-BR').includes(term) ||
					message.author.toLocaleLowerCase('pt-BR').includes(term)),
		);
	}, [workspace.messages, workspace.selectedChannelId, search]);

	const draft = channel == null ? '' : (workspace.drafts[channel.id] ?? '');

	function selectCommunity(target: DevCommunity): void {
		setEditingId(null);
		setSearch('');
		setWorkspace((current) => ({
			...current,
			selectedCommunityId: target.id,
			selectedChannelId: target.channels[0]?.id ?? null,
		}));
	}

	function selectChannel(id: string): void {
		setEditingId(null);
		setSearch('');
		setWorkspace((current) => ({...current, selectedChannelId: id}));
	}

	function openDialog(kind: DialogKind, targetId?: string): void {
		setDialog({kind, targetId});
		if (kind === 'rename-community') setDialogValue(community?.name ?? '');
		else if (kind === 'rename-channel') setDialogValue(channel?.name ?? '');
		else if (kind === 'profile') setDialogValue(workspace.displayName);
		else setDialogValue('');
		setDialogTopic(kind === 'rename-channel' ? (channel?.topic ?? '') : '');
	}

	function submitDialog(event: FormEvent<HTMLFormElement>): void {
		event.preventDefault();
		if (dialog == null) return;
		const name = dialogValue.trim();
		const topic = dialogTopic.trim();
		if (!['delete-community', 'delete-channel', 'reset'].includes(dialog.kind) && !name) return;

		switch (dialog.kind) {
			case 'create-community': {
				const guildId = newId();
				const firstChannelId = newId();
				setWorkspace((current) => ({
					...current,
					communities: [
						...current.communities,
						{
							id: guildId,
							name: name.slice(0, 64),
							channels: [{id: firstChannelId, name: 'geral', topic: 'Canal geral'}],
						},
					],
					selectedCommunityId: guildId,
					selectedChannelId: firstChannelId,
				}));
				break;
			}
			case 'rename-community':
				setWorkspace((current) => ({
					...current,
					communities: current.communities.map((entry) =>
						entry.id === dialog.targetId ? {...entry, name: name.slice(0, 64)} : entry,
					),
				}));
				break;
			case 'delete-community':
				setWorkspace((current) => {
					const communities = current.communities.filter((entry) => entry.id !== dialog.targetId);
					const keepChannels = new Set(communities.flatMap((entry) => entry.channels.map((item) => item.id)));
					const selected = communities[0] ?? null;
					return {
						...current,
						communities,
						messages: current.messages.filter((message) => keepChannels.has(message.channelId)),
						selectedCommunityId: selected?.id ?? null,
						selectedChannelId: selected?.channels[0]?.id ?? null,
					};
				});
				break;
			case 'create-channel': {
				if (community == null) break;
				const newChannel = {
					id: newId(),
					name: name.slice(0, 48).replace(/^#+/, '') || 'canal',
					topic: topic.slice(0, 140),
				};
				setWorkspace((current) => ({
					...current,
					communities: current.communities.map((entry) =>
						entry.id === community.id ? {...entry, channels: [...entry.channels, newChannel]} : entry,
					),
					selectedChannelId: newChannel.id,
				}));
				break;
			}
			case 'rename-channel':
				setWorkspace((current) => ({
					...current,
					communities: current.communities.map((entry) => ({
						...entry,
						channels: entry.channels.map((item) =>
							item.id === dialog.targetId
								? {...item, name: name.slice(0, 48).replace(/^#+/, '') || 'canal', topic: topic.slice(0, 140)}
								: item,
						),
					})),
				}));
				break;
			case 'delete-channel':
				setWorkspace((current) => {
					const communities = current.communities.map((entry) => ({
						...entry,
						channels: entry.channels.filter((item) => item.id !== dialog.targetId),
					}));
					const selected = communities.find((entry) => entry.id === current.selectedCommunityId);
					const drafts = {...current.drafts};
					if (dialog.targetId != null) delete drafts[dialog.targetId];
					return {
						...current,
						communities,
						drafts,
						messages: current.messages.filter((message) => message.channelId !== dialog.targetId),
						selectedChannelId: selected?.channels[0]?.id ?? null,
					};
				});
				break;
			case 'profile':
				setWorkspace((current) => ({...current, displayName: name.slice(0, 48)}));
				break;
			case 'reset':
				setWorkspace(freshDevWorkspace());
				setSearch('');
				setEditingId(null);
				break;
		}
		setDialog(null);
	}

	function setDraft(value: string): void {
		if (channel == null) return;
		const id = channel.id;
		setWorkspace((current) => ({...current, drafts: {...current.drafts, [id]: value}}));
	}

	function sendMessage(): void {
		if (channel == null || !draft.trim()) return;
		const message: DevMessage = {
			id: newId(),
			channelId: channel.id,
			body: draft.trim().slice(0, 4000),
			author: workspace.displayName,
			createdAt: Date.now(),
			edited: false,
			liked: false,
		};
		setWorkspace((current) => ({
			...current,
			messages: [...current.messages, message],
			drafts: {...current.drafts, [channel.id]: ''},
		}));
	}

	function handleComposerKeyDown(event: KeyboardEvent<HTMLTextAreaElement>): void {
		if (event.key === 'Enter' && !event.shiftKey && !event.nativeEvent.isComposing) {
			event.preventDefault();
			sendMessage();
		}
	}

	function saveEditedMessage(id: string): void {
		if (!editingBody.trim()) return;
		setWorkspace((current) => ({
			...current,
			messages: current.messages.map((message) =>
				message.id === id ? {...message, body: editingBody.trim().slice(0, 4000), edited: true} : message,
			),
		}));
		setEditingId(null);
		setEditingBody('');
	}

	function deleteMessage(id: string): void {
		setWorkspace((current) => ({...current, messages: current.messages.filter((message) => message.id !== id)}));
	}

	function toggleLike(id: string): void {
		setWorkspace((current) => ({
			...current,
			messages: current.messages.map((message) => (message.id === id ? {...message, liked: !message.liked} : message)),
		}));
	}

	return (
		<main className={styles.workspace} aria-label="Star modo Dev" data-testid="star-dev-workspace">
			<nav className={styles.communityRail} aria-label="Comunidades Dev">
				<div className={styles.railLogo} title="Star Dev">
					<StarLogo role="img" aria-label="Star" />
				</div>
				<div className={styles.railRule} />
				<div className={styles.communityList}>
					{workspace.communities.map((entry) => (
						<button
							key={entry.id}
							type="button"
							className={`${styles.communityButton} ${entry.id === workspace.selectedCommunityId ? styles.communitySelected : ''}`}
							onClick={() => selectCommunity(entry)}
							title={entry.name}
							aria-label={`Abrir comunidade ${entry.name}`}
							aria-pressed={entry.id === workspace.selectedCommunityId}
						>
							{initials(entry.name)}
						</button>
					))}
					<button
						type="button"
						className={styles.addCommunity}
						aria-label="Criar comunidade"
						title="Criar comunidade"
						onClick={() => openDialog('create-community')}
					>
						<PlusIcon size={23} />
					</button>
				</div>
			</nav>

			<aside className={styles.channelPanel} aria-label="Canais">
				<div className={styles.communityHeader}>
					<span className={styles.communityTitle} title={community?.name}>
						{community?.name ?? 'Seu espaço'}
					</span>
					{community != null && (
						<button
							type="button"
							title="Renomear comunidade"
							aria-label="Renomear comunidade"
							onClick={() => openDialog('rename-community', community.id)}
						>
							<PencilSimpleIcon size={17} />
						</button>
					)}
				</div>
				<div className={styles.channelHeading}>
					<span>CANAIS DE TEXTO</span>
					<button
						type="button"
						onClick={() => openDialog(community ? 'create-channel' : 'create-community')}
						title="Criar canal ou comunidade"
						aria-label="Criar canal"
					>
						<PlusIcon size={17} />
					</button>
				</div>
				<div className={styles.channelList}>
					{community?.channels.map((item) => (
						<button
							key={item.id}
							type="button"
							className={`${styles.channelButton} ${item.id === channel?.id ? styles.channelSelected : ''}`}
							onClick={() => selectChannel(item.id)}
							aria-pressed={item.id === channel?.id}
						>
							<span className={styles.hash}>#</span>
							<span className={styles.channelName}>{item.name}</span>
						</button>
					))}
					{!community && <p className={styles.sidebarHint}>Crie uma comunidade para começar.</p>}
					{community?.channels.length === 0 && <p className={styles.sidebarHint}>Crie seu primeiro canal.</p>}
				</div>
				<div className={styles.sidebarFooter}>
					{community != null && (
						<button
							type="button"
							className={styles.deleteGuild}
							onClick={() => openDialog('delete-community', community.id)}
						>
							<TrashIcon size={16} /> Excluir comunidade
						</button>
					)}
					<button
						type="button"
						className={styles.profile}
						onClick={() => openDialog('profile')}
						title="Editar perfil de desenvolvimento"
					>
						<span className={styles.avatar}>{initials(workspace.displayName)}</span>
						<span className={styles.profileName}>
							<strong>{workspace.displayName}</strong>
							<small>Desenvolvimento local</small>
						</span>
						<PencilSimpleIcon size={16} />
					</button>
				</div>
			</aside>

			<section className={styles.chatPanel} aria-label="Conversa Dev">
				<header className={styles.chatHeader}>
					<div className={styles.chatIdentity}>
						<strong>{channel == null ? 'Star Dev' : `# ${channel.name}`}</strong>
						<small>{channel?.topic ?? 'Ambiente isolado, sem conexão com servidores reais'}</small>
					</div>
					{channel != null && (
						<div className={styles.channelActions}>
							<button type="button" onClick={() => openDialog('rename-channel', channel.id)} title="Editar canal">
								Editar
							</button>
							<button type="button" onClick={() => openDialog('delete-channel', channel.id)} title="Excluir canal">
								Excluir
							</button>
						</div>
					)}
				</header>
				<div className={styles.devBanner} role="status">
					<span className={styles.devTag}>DEV</span>
					<span>
						{cacheAvailable
							? 'Tudo que você criar aqui fica somente no cache desta sessão.'
							: 'Armazenamento indisponível: alterações guardadas apenas enquanto esta tela estiver aberta.'}
					</span>
					<button type="button" onClick={() => openDialog('reset')} title="Limpar cache Dev">
						Limpar
					</button>
					<button type="button" className={styles.exitButton} onClick={leaveDevSession}>
						Sair do Dev
					</button>
				</div>
				{channel == null ? (
					<div className={styles.emptyState}>
						<div className={styles.emptySymbol}>✦</div>
						<h2>Bem-vindo ao Star Dev</h2>
						<p>
							Crie uma comunidade e canais para testar mensagens e alterações localmente, sem precisar entrar com uma
							conta.
						</p>
						<button
							type="button"
							className={styles.primaryButton}
							onClick={() => openDialog(community == null ? 'create-community' : 'create-channel')}
						>
							<PlusIcon size={18} /> {community == null ? 'Criar comunidade' : 'Criar canal'}
						</button>
					</div>
				) : (
					<>
						<div className={styles.searchBar}>
							<label htmlFor="star-dev-search">Pesquisar mensagens</label>
							<input
								id="star-dev-search"
								type="search"
								placeholder={`Buscar em #${channel.name}`}
								value={search}
								onChange={(event) => setSearch(event.target.value)}
							/>
						</div>
						<div className={styles.messageList} role="log" aria-label="Mensagens do canal">
							{currentMessages.length === 0 && (
								<div className={styles.noMessages}>
									{search ? 'Nenhuma mensagem encontrada.' : 'Este canal está vazio. Envie sua primeira mensagem!'}
								</div>
							)}
							{currentMessages.map((message) => (
								<article key={message.id} className={styles.message} data-testid="star-dev-message">
									<span className={styles.messageAvatar}>{initials(message.author)}</span>
									<div className={styles.messageContent}>
										<div className={styles.messageTop}>
											<strong>{message.author}</strong>
											<time dateTime={new Date(message.createdAt).toISOString()}>{formatTime(message.createdAt)}</time>
											{message.edited && <small>(editada)</small>}
										</div>
										{editingId === message.id ? (
											<div className={styles.editBox}>
												<textarea
													aria-label="Editar mensagem"
													value={editingBody}
													onChange={(event) => setEditingBody(event.target.value)}
													maxLength={4000}
													rows={3}
												/>
												<div>
													<button type="button" onClick={() => setEditingId(null)}>
														Cancelar
													</button>
													<button
														type="button"
														onClick={() => saveEditedMessage(message.id)}
														disabled={!editingBody.trim()}
													>
														Salvar
													</button>
												</div>
											</div>
										) : (
											<p className={styles.messageBody}>{message.body}</p>
										)}
										<div className={styles.messageActions}>
											<button
												type="button"
												aria-pressed={message.liked}
												onClick={() => toggleLike(message.id)}
												title="Reagir à mensagem"
											>
												{message.liked ? '♥ 1' : '♡ Reagir'}
											</button>
											<button
												type="button"
												onClick={() => {
													setEditingId(message.id);
													setEditingBody(message.body);
												}}
											>
												Editar
											</button>
											<button type="button" onClick={() => deleteMessage(message.id)} title="Excluir mensagem">
												Excluir
											</button>
										</div>
									</div>
								</article>
							))}
						</div>
						<form
							className={styles.composer}
							onSubmit={(event) => {
								event.preventDefault();
								sendMessage();
							}}
						>
							<label htmlFor="star-dev-composer">Mensagem em #{channel.name}</label>
							<div className={styles.composerRow}>
								<textarea
									id="star-dev-composer"
									rows={2}
									maxLength={4000}
									placeholder={`Enviar mensagem para #${channel.name}`}
									value={draft}
									onChange={(event) => setDraft(event.target.value)}
									onKeyDown={handleComposerKeyDown}
								/>
								<button className={styles.primaryButton} type="submit" disabled={!draft.trim()}>
									Enviar
								</button>
							</div>
							<small>Enter envia · Shift+Enter quebra linha · conteúdo local desta sessão</small>
						</form>
					</>
				)}
			</section>

			{dialog != null && (
				<div className={styles.modalBackdrop}>
					<form
						className={styles.modal}
						role="dialog"
						aria-modal="true"
						aria-labelledby="star-dev-dialog-title"
						onSubmit={submitDialog}
					>
						<h2 id="star-dev-dialog-title">{dialogTitles[dialog.kind]}</h2>
						{['reset', 'delete-community', 'delete-channel'].includes(dialog.kind) ? (
							<p className={styles.modalHint}>
								Esta ação remove somente os dados locais do modo Dev. Nenhum dado do servidor Star será afetado.
							</p>
						) : (
							<>
								<label htmlFor="star-dev-name">{dialog.kind === 'profile' ? 'Nome de exibição' : 'Nome'}</label>
								<input
									id="star-dev-name"
									required
									maxLength={64}
									value={dialogValue}
									onChange={(event) => setDialogValue(event.target.value)}
									placeholder="Digite um nome"
								/>
								{['create-channel', 'rename-channel'].includes(dialog.kind) && (
									<>
										<label htmlFor="star-dev-topic">Descrição do canal (opcional)</label>
										<input
											id="star-dev-topic"
											maxLength={140}
											value={dialogTopic}
											onChange={(event) => setDialogTopic(event.target.value)}
										/>
									</>
								)}
							</>
						)}
						<div className={styles.modalButtons}>
							<button type="button" onClick={() => setDialog(null)}>
								Cancelar
							</button>
							<button className={styles.primaryButton} type="submit">
								{dialog.kind.startsWith('delete') || dialog.kind === 'reset' ? 'Confirmar' : 'Salvar'}
							</button>
						</div>
					</form>
				</div>
			)}
		</main>
	);
}
