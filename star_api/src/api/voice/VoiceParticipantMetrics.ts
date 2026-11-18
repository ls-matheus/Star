// SPDX-License-Identifier: AGPL-3.0-or-later

import {registerCounter} from '@star/hono/src/middleware/Metrics';

export const voiceParticipantsDisconnectedTotal = registerCounter(
	'star_api_voice_participants_disconnected_total',
	'LiveKit participants removed because they had no matching voice state, by reason',
);
export const voiceParticipantConfirmUnavailableTotal = registerCounter(
	'star_api_voice_participant_confirm_unavailable_total',
	'LiveKit participant joins left in place because the gateway confirm did not answer',
);
export const voiceParticipantSweepCandidatesTotal = registerCounter(
	'star_api_voice_participant_sweep_candidates_total',
	'LiveKit participants seen without a matching voice state during a sweep',
);
