package stronzflix.app

import android.content.pm.PackageManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.ryanheise.audioservice.AudioServiceActivity;

class MainActivity: AudioServiceActivity () {

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "stronzflix.app/is_tv").setMethodCallHandler {
            call, result ->
            if (call.method == "isTV") {
                val isTV : Boolean = packageManager?.hasSystemFeature(PackageManager.FEATURE_TELEVISION) ?: false
                result.success(isTV)
            } else {
                result.notImplemented()
            }
        }
    }
}
