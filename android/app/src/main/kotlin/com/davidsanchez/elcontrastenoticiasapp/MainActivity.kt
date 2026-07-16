package com.davidsanchez.elcontrastenoticiasapp

import com.ryanheise.audioservice.AudioServiceActivity
import android.content.Intent

class MainActivity: AudioServiceActivity() {
    // Este método es importante para audio_service
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
