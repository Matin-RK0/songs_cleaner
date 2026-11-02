package com.example.songs_cleaner

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PendingPlayRequestTest {
    @Test fun normalLaunchHasNoPlayCommand() {
        assertFalse(PendingPlayRequest { 0L }.consume())
    }

    @Test fun coldStartCommandIsConsumedOnce() {
        val request = PendingPlayRequest { 0L }
        request.request()
        assertTrue(request.consume())
        assertFalse(request.consume())
    }

    @Test fun liveDeliveryLeavesNothingForStartupPolling() {
        val request = PendingPlayRequest { 0L }
        request.request()
        assertTrue(request.consume()) // playRequested
        assertFalse(request.consume()) // consumePendingPlay
        request.request()
        assertTrue(request.consume()) // a new explicit press still works
    }

    @Test fun abandonedStartupDoesNotReplayLater() {
        var time = 0L
        val request = PendingPlayRequest { time }
        request.request()
        time = 30_001L
        assertFalse(request.consume())
        assertFalse(request.consume())
    }

    @Test fun processRestartDoesNotRestoreCommands() {
        val oldProcess = PendingPlayRequest { 0L }
        oldProcess.request()
        assertFalse(PendingPlayRequest { 0L }.consume())
    }
}
