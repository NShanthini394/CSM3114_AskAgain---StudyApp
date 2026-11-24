package com.shanthini.askagain

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(engine: io.flutter.embedding.engine.FlutterEngine) {
        super.configureFlutterEngine(engine)
        com.tom_roush.pdfbox.android.PDFBoxResourceLoader.init(applicationContext)
        val messenger = engine.dartExecutor.binaryMessenger
        io.flutter.plugin.common.MethodChannel(messenger, "askagain/pdf",
            io.flutter.plugin.common.StandardMethodCodec.INSTANCE, messenger.makeBackgroundTaskQueue())
            .setMethodCallHandler { call, result ->
                if (call.method != "pages") { result.notImplemented(); return@setMethodCallHandler }
                try {
                    val bytes = call.arguments as ByteArray
                    require(bytes.size <= 24 * 1024 * 1024) { "Choose a smaller PDF." }
                    val pages = com.tom_roush.pdfbox.pdmodel.PDDocument.load(bytes).use { doc ->
                        val reader = com.tom_roush.pdfbox.text.PDFTextStripper()
                        (1..doc.numberOfPages).map { page ->
                            reader.startPage = page
                            reader.endPage = page
                            reader.getText(doc)
                        }
                    }
                    result.success(pages)
                } catch (e: Exception) {
                    result.error("pdf", "Could not read this PDF. Use an unlocked PDF with selectable text.", null)
                }
            }
        io.flutter.plugin.common.MethodChannel(engine.dartExecutor.binaryMessenger, "askagain/config")
            .setMethodCallHandler { call, result ->
                if (call.method == "configured") {
                    result.success(resources.getIdentifier("google_app_id", "string", packageName) != 0)
                } else if (call.method == "googleClientId") {
                    val id = resources.getIdentifier("default_web_client_id", "string", packageName)
                    result.success(if (id == 0) null else getString(id))
                } else result.notImplemented()
            }
    }
}
