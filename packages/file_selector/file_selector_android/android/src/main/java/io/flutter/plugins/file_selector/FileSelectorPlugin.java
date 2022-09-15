package io.flutter.plugins.file_selector;

import androidx.annotation.NonNull;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;

/** FileSelectorPlugin */
public class FileSelectorPlugin implements FlutterPlugin, MethodCallHandler {
  /// The MethodChannel that will the communication between Flutter and native
  /// Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine
  /// and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel channel;
  private static final String CHANNEL = "plugins.flutter.io/file_selector_android";

  static final String METHOD_CALL_OPEN_FILE = "openFile";
  static final String METHOD_CALL_GET_DIRECTORY_PATH = "getDirectoryPath";
  static final String METHOD_CALL_OPEN_FILES = "openFiles";
  static final String METHOD_CALL_GET_SAVE_PATH = "getSavePath";

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), CHANNEL);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {
    switch (call.method) {
      case METHOD_CALL_OPEN_FILE:
        throw new UnsupportedOperationException("Method 'openFile' not supported yet.");
      case METHOD_CALL_GET_DIRECTORY_PATH:
        throw new UnsupportedOperationException("Method 'getDirectoryPath' not supported yet.");
      case METHOD_CALL_OPEN_FILES:
        throw new UnsupportedOperationException("Method 'openFiles' not supported yet.");
      case METHOD_CALL_GET_SAVE_PATH:
        throw new UnsupportedOperationException("Method 'getSavePath' not supported yet.");
      default:
        throw new IllegalArgumentException("Unknown method " + call.method);
    }
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    channel.setMethodCallHandler(null);
  }
}
