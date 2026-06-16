package com.gongziming.share_bridge_qq

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import com.tencent.connect.share.QQShare
import com.tencent.connect.share.QzoneShare
import com.tencent.tauth.IUiListener
import com.tencent.tauth.Tencent
import com.tencent.tauth.UiError
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.ActivityResultListener
import java.io.File
import java.util.ArrayList

/** ShareBridgeQqPlugin */
class ShareBridgeQqPlugin :
    FlutterPlugin,
    MethodCallHandler,
    ActivityAware,
    ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var tencent: Tencent? = null
    private var pendingResult: Result? = null
    private var pendingListener: IUiListener? = null

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "share_bridge_qq")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "setPrivacyGranted" -> setPrivacyGranted(call, result)
            "isInstalled" -> result.success(isInstalled())
            "supports" -> result.success(supports(call))
            "shareWebPage" -> shareWebPage(call, result)
            "shareImage" -> shareImage(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        activityBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activityBinding?.removeActivityResultListener(this)
        activityBinding = null
        activity = null
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        val listener = pendingListener ?: return false
        return Tencent.onActivityResultData(requestCode, resultCode, data, listener)
    }

    private fun initialize(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId")?.trim().orEmpty()
        if (appId.isEmpty()) {
            result.error("configError", "QQ appId 不能为空。", null)
            return
        }
        val authorities = "${applicationContext.packageName}.fileprovider"
        try {
            tencent = Tencent.createInstance(appId, applicationContext, authorities)
            result.success(null)
        } catch (error: Throwable) {
            result.error("configError", "QQ SDK 初始化失败：${error.message}", null)
        }
    }

    private fun setPrivacyGranted(call: MethodCall, result: Result) {
        val granted = call.argument<Boolean>("granted") ?: false
        Tencent.setIsPermissionGranted(granted)
        result.success(null)
    }

    private fun isInstalled(): Boolean {
        val instance = tencent ?: return false
        return try {
            instance.isQQInstalled(applicationContext)
        } catch (_: Throwable) {
            false
        }
    }

    private fun supports(call: MethodCall): Boolean {
        val channel = call.argument<String>("channel")
        val contentType = call.argument<String>("contentType")
        if (channel == "qq.friend") {
            return contentType in setOf("webpage", "image")
        }
        if (channel == "qq.qzone") {
            return contentType == "webpage"
        }
        return false
    }

    private fun shareWebPage(call: MethodCall, result: Result) {
        val title = call.argument<String>("title").orEmpty()
        val description = call.argument<String>("description").orEmpty()
        val url = call.argument<String>("url").orEmpty()
        if (title.isBlank() || description.isBlank() || url.isBlank()) {
            result.success(resultMap("invalidArgument", "title、description、url 不能为空。"))
            return
        }

        val params = Bundle().apply {
            putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_DEFAULT)
            putString(QQShare.SHARE_TO_QQ_TITLE, title)
            putString(QQShare.SHARE_TO_QQ_SUMMARY, description)
            putString(QQShare.SHARE_TO_QQ_TARGET_URL, url)
            imageFile(call, "thumbnail")?.let {
                putString(QQShare.SHARE_TO_QQ_IMAGE_LOCAL_URL, it.absolutePath)
                putStringArrayList(QzoneShare.SHARE_TO_QQ_IMAGE_URL, arrayListOf(it.absolutePath))
            }
        }
        share(call, result, params)
    }

    private fun shareImage(call: MethodCall, result: Result) {
        val channel = call.argument<String>("channel").orEmpty()
        if (channel == "qq.qzone") {
            result.success(resultMap("unsupportedContent", "QQ 空间纯图片分享暂不作为 Android MVP 能力。"))
            return
        }
        val imageFile = imageFile(call, "image")
        if (imageFile == null) {
            result.success(resultMap("invalidArgument", "image 必须是可读文件或非空字节。"))
            return
        }

        val params = Bundle().apply {
            putInt(QQShare.SHARE_TO_QQ_KEY_TYPE, QQShare.SHARE_TO_QQ_TYPE_IMAGE)
            putString(QQShare.SHARE_TO_QQ_IMAGE_LOCAL_URL, imageFile.absolutePath)
        }
        share(call, result, params)
    }

    private fun imageFile(call: MethodCall, key: String): File? {
        val source = call.argument<Map<String, Any?>>(key) ?: return null
        return when (source["type"] as? String) {
            "file" -> {
                val path = (source["path"] as? String)?.takeIf { it.isNotBlank() } ?: return null
                val file = File(path)
                file.takeIf { it.exists() && it.canRead() }
            }
            "memory" -> {
                val bytes = source["bytes"] as? ByteArray ?: return null
                if (bytes.isEmpty()) return null
                val file = File.createTempFile("share_bridge_qq_", ".img", applicationContext.cacheDir)
                file.writeBytes(bytes)
                file
            }
            else -> null
        }
    }

    private fun share(call: MethodCall, result: Result, params: Bundle) {
        val instance = tencent
        if (instance == null) {
            result.success(resultMap("sdkNotInitialized", "QQ SDK 尚未初始化。"))
            return
        }
        val currentActivity = activity
        if (currentActivity == null) {
            result.success(resultMap("nativeError", "当前没有可用 Activity。"))
            return
        }
        if (pendingResult != null) {
            result.success(resultMap("busy", "已有 QQ 分享请求等待回调。"))
            return
        }

        val channel = call.argument<String>("channel").orEmpty()
        val listener = createListener()
        pendingResult = result
        pendingListener = listener

        try {
            when (channel) {
                "qq.friend" -> {
                    instance.shareToQQ(currentActivity, params, listener)
                }
                "qq.qzone" -> {
                    val qzoneParams = Bundle(params)
                    qzoneParams.putInt(
                        QzoneShare.SHARE_TO_QZONE_KEY_TYPE,
                        QzoneShare.SHARE_TO_QZONE_TYPE_IMAGE_TEXT
                    )
                    if (!qzoneParams.containsKey(QzoneShare.SHARE_TO_QQ_IMAGE_URL)) {
                        qzoneParams.putStringArrayList(QzoneShare.SHARE_TO_QQ_IMAGE_URL, ArrayList<String>())
                    }
                    instance.shareToQzone(currentActivity, qzoneParams, listener)
                }
                else -> {
                    completePending(resultMap("unsupportedChannel", "不支持的 QQ 渠道：$channel"))
                }
            }
        } catch (error: Throwable) {
            completePending(resultMap("nativeError", "QQ 分享调用失败：${error.message}"))
        }
    }

    private fun createListener(): IUiListener {
        return object : IUiListener {
            override fun onComplete(response: Any?) {
                completePending(resultMap("success", null, response))
            }

            override fun onError(error: UiError?) {
                val code = if (error?.errorCode == 30001) "permissionDenied" else "nativeError"
                completePending(resultMap(code, extractUiError(error)))
            }

            override fun onCancel() {
                completePending(resultMap("cancelled", "用户取消分享。"))
            }

            override fun onWarning(code: Int) {
                // QQ SDK warning is non-terminal; wait for complete/cancel/error.
            }
        }
    }

    private fun extractUiError(error: UiError?): String {
        if (error == null) {
            return "QQ SDK 返回未知错误。"
        }
        return "code=${error.errorCode}, message=${error.errorMessage}, detail=${error.errorDetail}"
    }

    private fun completePending(value: Map<String, Any?>) {
        val result = pendingResult
        pendingResult = null
        pendingListener = null
        result?.success(value)
    }

    private fun resultMap(
        code: String,
        message: String?,
        raw: Any? = null
    ): Map<String, Any?> {
        return mapOf(
            "code" to code,
            "message" to message,
            "raw" to raw?.toString()
        )
    }

}
