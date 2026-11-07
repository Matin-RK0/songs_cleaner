package com.example.songs_cleaner

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class PhoneCallStateTest {
    @Test fun noPermissionOrUnavailableSnapshotBlocksPresentation() {
        val state = PhoneCallState()
        assertTrue(state.blocksPlayer(false, false))
        assertTrue(state.blocksPlayer(true, null))
    }

    @Test fun ongoingCallBlocksEvenWithoutAnEarlierBroadcast() {
        assertTrue(PhoneCallState().blocksPlayer(true, true))
    }

    @Test fun ringingEventBlocksBeforeSnapshotCatchesUp() {
        val state = PhoneCallState()
        state.report(true)
        assertTrue(state.blocksPlayer(true, false))
        state.report(true)
        assertTrue(state.blocksPlayer(true, false))
    }

    @Test fun idleOnOneSimCannotUnblockAnotherSimCall() {
        val state = PhoneCallState()
        state.report(true)
        state.report(false)
        assertTrue(state.blocksPlayer(true, true))
    }

    @Test fun idleAllowsPresentationOnlyAfterAllCallsEnd() {
        val state = PhoneCallState()
        state.report(true)
        state.report(false)
        assertFalse(state.blocksPlayer(true, false))
    }
}
