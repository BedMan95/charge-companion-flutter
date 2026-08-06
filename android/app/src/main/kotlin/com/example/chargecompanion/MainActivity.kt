package id.my.fornubi.chargecompanion

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val CHANNEL = "id.my.fornubi.chargecompanion/version"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getAppVersion") {
                try {
                    val pInfo = context.packageManager.getPackageInfo(context.packageName, 0)
                    val version = pInfo.versionName
                    result.success(version)
                } catch (e: Exception) {
                    result.error("UNAVAILABLE", "Version name not available.", null)
                }
            } else {
                result.notImplemented()
            }
        }
    }
}
