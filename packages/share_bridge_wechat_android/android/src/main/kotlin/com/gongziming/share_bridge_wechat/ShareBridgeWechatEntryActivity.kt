package com.gongziming.share_bridge_wechat

import android.app.Activity
import android.content.Intent
import android.os.Bundle

/** Base Activity for host apps' `${applicationId}.wxapi.WXEntryActivity`. */
open class ShareBridgeWechatEntryActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        handleIntent(intent)
        finish()
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIntent(intent)
        finish()
    }

    private fun handleIntent(intent: Intent?) {
        if (intent != null) {
            ShareBridgeWechatPlugin.handleIntent(intent)
        }
    }
}
