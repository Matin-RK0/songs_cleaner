package com.example.songs_cleaner

/** A cold-start command belongs to this process, never to a saved app session. */
internal class PendingPlayRequest(private val now: () -> Long) {
    private var requestedAt: Long? = null

    fun request() {
        requestedAt = now()
    }

    fun consume(): Boolean {
        val requested = requestedAt ?: return false
        requestedAt = null
        // Do not replay a command after a failed/abandoned Flutter startup.
        return now() - requested in 0L..30_000L
    }
}
