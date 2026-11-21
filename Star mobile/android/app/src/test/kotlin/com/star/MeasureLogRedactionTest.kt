package com.star

import org.junit.Assert.assertEquals
import org.junit.Test

class MeasureLogRedactionTest {
    @Test
    fun scrubsHttpUrlsAndSnowflakes() {
        assertEquals(
            "GET https://instance/channels failed",
            scrubForMeasure("GET https://my.guild.host/channels failed"),
        )
        assertEquals(
            "Message :id not found for email",
            scrubForMeasure("Message 1558635549802102784 not found for someone@example.com"),
        )
    }

    @Test
    fun scrubsHostLookupMessages() {
        assertEquals(
            "SocketException: Failed host lookup: 'instance' (OS Error)",
            scrubForMeasure(
                "SocketException: Failed host lookup: 'chat.example.org' (OS Error)",
            ),
        )
    }

    @Test
    fun redactThrowableScrubsMessageAndKeepsStackTrace() {
        val original =
            IllegalStateException(
                "Failed for chat.example.org channel 1558633981610557440",
            )
        original.stackTrace = arrayOf(StackTraceElement("com.star.Test", "run", "Test.kt", 12))

        val redacted = redactThrowableForMeasure(original)

        assertEquals(
            "Failed for instance channel :id",
            redacted.message,
        )
        assertEquals(1, redacted.stackTrace.size)
        assertEquals("Test.kt", redacted.stackTrace[0].fileName)
    }

    @Test
    fun starNativeMeasureScrubAttribute() {
        assertEquals(
            "host instance",
            StarNativeMeasure.scrubAttribute("host chat.example.org"),
        )
        assertEquals(256, StarNativeMeasure.scrubAttribute("x".repeat(300)).length)
    }
}
