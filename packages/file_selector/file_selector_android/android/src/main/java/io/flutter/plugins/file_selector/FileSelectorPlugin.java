package io.flutter.plugins.file_selector;

import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.util.Arrays;
import java.util.List;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugins.file_selector.Messages.FileSelectorApi;

/** FileSelectorPlugin */
public class FileSelectorPlugin implements FlutterPlugin, FileSelectorApi {
  static final String TAG = "FileSelectorPlugin";

  public FileSelectorPlugin() {
  }

  private void setup(BinaryMessenger messenger, Context context) {
    BinaryMessenger.TaskQueue taskQueue = messenger.makeBackgroundTaskQueue();

    try {
      FileSelectorApi.setup(messenger, this);
    } catch (Exception ex) {
      Log.e(TAG, "Received exception while setting up FileSelectorPlugin", ex);
    }
  }

  @SuppressWarnings("deprecation")
  public static void registerWith(io.flutter.plugin.common.PluginRegistry.Registrar registrar) {
    FileSelectorPlugin instance = new FileSelectorPlugin();
    instance.setup(registrar.messenger(), registrar.context());
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    setup(binding.getBinaryMessenger(), binding.getApplicationContext());
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    FileSelectorApi.setup(binding.getBinaryMessenger(), null);
  }

  @NonNull
  @Override
  public List<String> startFileExplorer(@NonNull Messages.FileSelectorMethod method,
      @NonNull Messages.SelectionOptions options, @Nullable String initialDirectory,
      @Nullable String confirmButtonText) {
    switch (method) {
      case OPEN_FILE:
        return Arrays.asList("A");
      case GET_DIRECTORY_PATH:
        return Arrays.asList("B");
      case OPEN_MULTIPLE_FILES:
        return Arrays.asList("B", "C");
      default:
        return Arrays.asList("A", "B", "C");
    }
  }

  @Nullable
  @Override
  public String openSaveDialog(@NonNull Messages.SelectionOptions options, @Nullable String initialDirectory,
      @Nullable String confirmButtonText, @Nullable String suggestedName) {
    return null;
  }
}
