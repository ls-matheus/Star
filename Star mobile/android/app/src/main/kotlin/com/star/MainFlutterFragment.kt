package com.star

import io.flutter.embedding.android.FlutterFragment

class MainFlutterFragment : FlutterFragment() {
    override fun popSystemNavigator(): Boolean {
        activity?.moveTaskToBack(true)
        return true
    }
}
