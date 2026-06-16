package com.gongziming.share_bridge_wechat

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import com.tencent.mm.opensdk.modelbase.BaseReq
import com.tencent.mm.opensdk.modelbase.BaseResp
import com.tencent.mm.opensdk.modelmsg.SendMessageToWX
import com.tencent.mm.opensdk.modelmsg.WXImageObject
import com.tencent.mm.opensdk.modelmsg.WXMediaMessage
import com.tencent.mm.opensdk.modelmsg.WXWebpageObject
import com.tencent.mm.opensdk.openapi.IWXAPI
import com.tencent.mm.opensdk.openapi.IWXAPIEventHandler
import com.tencent.mm.opensdk.openapi.WXAPIFactory
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.io.ByteArrayOutputStream
import java.io.File

/** ShareBridgeWechatPlugin */
class ShareBridgeWechatPlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler(this)
        appContext = applicationContext
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "initialize" -> initialize(call, result)
            "isInstalled" -> result.success(api?.isWXAppInstalled ?: false)
            "supports" -> result.success(supports(call))
            "shareWebPage" -> shareWebPage(call, result)
            "shareImage" -> shareImage(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        if (appContext === applicationContext) {
            appContext = null
        }
    }

    private fun initialize(call: MethodCall, result: Result) {
        val appId = call.argument<String>("appId")?.trim().orEmpty()
        if (appId.isEmpty()) {
            result.error("configError", "WeChat appId must not be empty.", null)
            return
        }

        currentAppId = appId
        api = WXAPIFactory.createWXAPI(applicationContext, appId, true)
        val registered = api?.registerApp(appId) ?: false
        if (!registered) {
            result.error("configError", "WeChat registerApp returned false.", null)
            return
        }
        result.success(null)
    }

    private fun supports(call: MethodCall): Boolean {
        val channel = call.argument<String>("channel")
        val contentType = call.argument<String>("contentType")
        return channel in WECHAT_CHANNELS && contentType in setOf("webpage", "image")
    }

    private fun shareWebPage(call: MethodCall, result: Result) {
        val url = call.argument<String>("url").orEmpty()
        val title = call.argument<String>("title").orEmpty()
        val description = call.argument<String>("description").orEmpty()
        if (url.isBlank() || title.isBlank() || description.isBlank()) {
            result.success(resultMap("invalidArgument", "title, description, and url must not be empty."))
            return
        }

        val message = WXMediaMessage(WXWebpageObject(url)).apply {
            this.title = title
            this.description = description
            imageSource(call, "thumbnail")?.let { thumbnail ->
                thumbData = loadThumbData(thumbnail)
            }
        }
        sendMessage(call, result, message)
    }

    private fun shareImage(call: MethodCall, result: Result) {
        val imageSource = imageSource(call, "image")
        if (imageSource == null) {
            result.success(resultMap("invalidArgument", "image must be a readable file or non-empty bytes."))
            return
        }

        val imageObject = when (imageSource) {
            is ImageSource.FileSource -> WXImageObject().apply {
                setImagePath(imageSource.file.absolutePath)
            }
            is ImageSource.MemorySource -> WXImageObject(imageSource.bytes)
        }
        val message = WXMediaMessage(imageObject).apply {
            thumbData = imageSource(call, "thumbnail")?.let { loadThumbData(it) }
                ?: loadThumbData(imageSource)
        }
        sendMessage(call, result, message)
    }

    private fun sendMessage(
        call: MethodCall,
        result: Result,
        message: WXMediaMessage
    ) {
        val wxApi = api
        if (wxApi == null) {
            result.success(resultMap("sdkNotInitialized", "WeChat SDK has not been initialized."))
            return
        }
        if (!wxApi.isWXAppInstalled) {
            result.success(resultMap("appNotInstalled", "WeChat is not installed."))
            return
        }

        val requestId = call.argument<String>("requestId").orEmpty()
        val channel = call.argument<String>("channel").orEmpty()
        val scene = when (channel) {
            "wechat.session" -> SendMessageToWX.Req.WXSceneSession
            "wechat.timeline" -> SendMessageToWX.Req.WXSceneTimeline
            else -> {
                result.success(resultMap("unsupportedChannel", "Unsupported WeChat channel: $channel"))
                return
            }
        }

        synchronized(lock) {
            if (pendingResult != null) {
                result.success(resultMap("busy", "A WeChat share request is already pending."))
                return
            }
            pendingResult = result
            pendingRequestId = requestId
        }

        val request = SendMessageToWX.Req().apply {
            transaction = requestId
            this.message = message
            this.scene = scene
        }

        val sent = wxApi.sendReq(request)
        if (!sent) {
            completePending(resultMap("nativeError", "WeChat sendReq returned false."))
            return
        }
        scheduleTimeout(requestId)
    }

    private fun imageSource(call: MethodCall, key: String): ImageSource? {
        val source = call.argument<Map<String, Any?>>(key) ?: return null
        return when (source["type"] as? String) {
            "file" -> {
                val path = (source["path"] as? String)?.takeIf { it.isNotBlank() } ?: return null
                val file = File(path)
                if (!file.exists() || !file.canRead()) return null
                ImageSource.FileSource(file)
            }
            "memory" -> {
                val bytes = source["bytes"] as? ByteArray ?: return null
                if (bytes.isEmpty()) return null
                ImageSource.MemorySource(bytes)
            }
            else -> null
        }
    }

    private fun loadThumbData(source: ImageSource): ByteArray? {
        val bitmap = when (source) {
            is ImageSource.FileSource -> BitmapFactory.decodeFile(source.file.absolutePath)
            is ImageSource.MemorySource -> BitmapFactory.decodeByteArray(
                source.bytes,
                0,
                source.bytes.size
            )
        } ?: return null
        val scaled = Bitmap.createScaledBitmap(bitmap, 120, 120, true)
        val output = ByteArrayOutputStream()
        var quality = 85
        do {
            output.reset()
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, output)
            quality -= 10
        } while (output.size() > MAX_THUMB_BYTES && quality >= 40)
        if (scaled !== bitmap) {
            scaled.recycle()
        }
        bitmap.recycle()
        return output.toByteArray().takeIf { it.size <= MAX_THUMB_BYTES }
    }

    private sealed class ImageSource {
        data class FileSource(val file: File) : ImageSource()
        data class MemorySource(val bytes: ByteArray) : ImageSource()
    }

    companion object {
        private const val CHANNEL_NAME = "share_bridge_wechat"
        private const val MAX_THUMB_BYTES = 32 * 1024
        private const val CALLBACK_TIMEOUT_MS = 120_000L
        private val WECHAT_CHANNELS = setOf("wechat.session", "wechat.timeline")
        private val lock = Any()
        private val mainHandler = Handler(Looper.getMainLooper())

        private var appContext: Context? = null
        private var currentAppId: String? = null
        private var api: IWXAPI? = null
        private var pendingResult: Result? = null
        private var pendingRequestId: String? = null

        fun handleIntent(intent: android.content.Intent): Boolean {
            val wxApi = api ?: createApiFromContext() ?: return false
            return wxApi.handleIntent(intent, object : IWXAPIEventHandler {
                override fun onReq(req: BaseReq) = Unit

                override fun onResp(resp: BaseResp) {
                    completePending(mapResponse(resp))
                }
            })
        }

        private fun createApiFromContext(): IWXAPI? {
            val context = appContext ?: return null
            val appId = currentAppId ?: return null
            return WXAPIFactory.createWXAPI(context, appId, true).also {
                api = it
                it.registerApp(appId)
            }
        }

        private fun scheduleTimeout(requestId: String) {
            mainHandler.postDelayed({
                synchronized(lock) {
                    if (pendingRequestId == requestId && pendingResult != null) {
                        completePending(resultMap("timeout", "Timed out waiting for WeChat callback."))
                    }
                }
            }, CALLBACK_TIMEOUT_MS)
        }

        private fun completePending(value: Map<String, Any?>) {
            val resultToComplete: Result?
            synchronized(lock) {
                resultToComplete = pendingResult
                pendingResult = null
                pendingRequestId = null
            }
            resultToComplete?.success(value)
        }

        private fun mapResponse(resp: BaseResp): Map<String, Any?> {
            val code = when (resp.errCode) {
                BaseResp.ErrCode.ERR_OK -> "success"
                BaseResp.ErrCode.ERR_USER_CANCEL -> "cancelled"
                BaseResp.ErrCode.ERR_AUTH_DENIED -> "permissionDenied"
                BaseResp.ErrCode.ERR_UNSUPPORT -> "unsupportedContent"
                BaseResp.ErrCode.ERR_SENT_FAILED -> "nativeError"
                BaseResp.ErrCode.ERR_COMM -> "nativeError"
                else -> "unknown"
            }
            return resultMap(code, resp.errStr, resp.transaction)
        }

        private fun resultMap(
            code: String,
            message: String?,
            requestId: String? = null
        ): Map<String, Any?> {
            return mapOf(
                "requestId" to requestId,
                "code" to code,
                "message" to message
            )
        }
    }
}
