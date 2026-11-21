package com.star.voice

import android.content.Context
import android.media.AudioManager
import android.os.Build
import org.junit.After
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [Build.VERSION_CODES.S])
class SystemVoiceCallGuardTest {
    @After
    fun tearDown() {
        StarRouteOwnership.holdsRoute = false
        audioManager().mode = AudioManager.MODE_NORMAL
    }

    @Test
    fun starVoiceOwnershipDefersToStar() {
        val context = RuntimeEnvironment.getApplication()
        assertFalse(isExternalVoiceCallActive(context, starOwnsVoice = true))
    }

    @Test
    fun idleDeviceWithoutStarVoiceIsNotExternalByDefault() {
        val context = RuntimeEnvironment.getApplication()
        assertFalse(isExternalVoiceCallActive(context, starOwnsVoice = false))
    }

    @Test
    fun communicationModeWithoutStarRouteIsExternal() {
        val context = RuntimeEnvironment.getApplication()
        audioManager().mode = AudioManager.MODE_IN_COMMUNICATION
        assertTrue(isExternalVoiceCallActive(context, starOwnsVoice = false))
    }

    @Test
    fun communicationModeFromStarRouteIsNotExternal() {
        val context = RuntimeEnvironment.getApplication()
        audioManager().mode = AudioManager.MODE_IN_COMMUNICATION
        StarRouteOwnership.holdsRoute = true
        assertFalse(isExternalVoiceCallActive(context, starOwnsVoice = false))
    }

    private fun audioManager(): AudioManager {
        return RuntimeEnvironment.getApplication()
            .getSystemService(Context.AUDIO_SERVICE) as AudioManager
    }
}
