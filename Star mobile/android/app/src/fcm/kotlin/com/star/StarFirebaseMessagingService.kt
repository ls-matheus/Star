package com.star

import com.google.firebase.messaging.FirebaseMessagingService

class StarFirebaseMessagingService : FirebaseMessagingService() {
    override fun onNewToken(token: String) {
        io.flutter.plugins.firebase.messaging.FlutterFirebaseTokenLiveData
            .getInstance()
            .postToken(token)
    }
}
