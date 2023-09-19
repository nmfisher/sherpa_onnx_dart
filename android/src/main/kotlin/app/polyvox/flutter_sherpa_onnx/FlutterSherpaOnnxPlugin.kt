package app.polyvox.flutter_sherpa_onnx

import androidx.annotation.NonNull
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.FlutterInjector

import java.io.FileReader
import java.io.BufferedReader
import java.io.InputStream
import java.io.InputStreamReader
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.FileNotFoundException

import android.content.res.AssetManager

import java.io.File

import android.content.Context
import android.os.ParcelFileDescriptor
import android.util.Log

import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import com.sun.jna.Structure
import com.sun.jna.NativeLibrary
import com.sun.jna.StringArray
import android.R.attr.path

/** FlutterSherpaOnnxPlugin */
class FlutterSherpaOnnxPlugin: FlutterPlugin, MethodCallHandler {

    protected val TAG: String = FlutterSherpaOnnxPlugin::class.java.getSimpleName()


    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel : MethodChannel

    private lateinit var context: Context

    companion object {
      init {
        
      }
    }


}