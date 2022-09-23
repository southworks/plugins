// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import android.app.Activity;
import android.app.Application;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import androidx.lifecycle.DefaultLifecycleObserver;
import android.webkit.MimeTypeMap;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleOwner;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.io.File;
import kotlin.NotImplementedError;
import java.util.HashMap;
import java.util.ArrayList;

/** Android platform implementation of the FileSelectorPlugin. */
public class FileSelectorPlugin
    implements MethodChannel.MethodCallHandler, FlutterPlugin, ActivityAware {

  static final String METHOD_GET_DIRECTORY_PATH = "getDirectoryPath";
  static final String METHOD_OPEN_FILE = "openFile";
  static final String METHOD_GET_SAVE_PATH = "getSavePath";
  private static boolean isMultipleSelection = false;
  private static String[] mimeTypes = null;
  private static final String CHANNEL = "plugins.flutter.io/file_selector_android";

  private FlutterPluginBinding pluginBinding;
  private ActivityStateHelper activityState;

  /**
   * Default constructor for the plugin.
   *
   * <p>Use this constructor for production code.
   */
  public FileSelectorPlugin() {}

  @VisibleForTesting
  FileSelectorPlugin(final FileSelectorDelegate delegate, final Activity activity) {
    activityState = new ActivityStateHelper(delegate, activity);
  }

  @VisibleForTesting
  final ActivityStateHelper getActivityState() {
    return activityState;
  }

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = binding;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    pluginBinding = null;
  }

  @Override
  public void onAttachedToActivity(@NonNull ActivityPluginBinding binding) {
    setup(
        pluginBinding.getBinaryMessenger(),
        (Application) pluginBinding.getApplicationContext(),
        binding.getActivity(),
        null,
        binding);
  }

  @Override
  public void onDetachedFromActivity() {
    tearDown();
  }

  @Override
  public void onDetachedFromActivityForConfigChanges() {
    onDetachedFromActivity();
  }

  @Override
  public void onReattachedToActivityForConfigChanges(@NonNull ActivityPluginBinding binding) {
    onAttachedToActivity(binding);
  }

  private void setup(
      final BinaryMessenger messenger,
      final Application application,
      final Activity activity,
      final PluginRegistry.Registrar registrar,
      final ActivityPluginBinding activityBinding) {
    activityState =
        new ActivityStateHelper(
            CHANNEL, application, activity, messenger, this, registrar, activityBinding);
  }

  private void tearDown() {
    if (activityState != null) {
      activityState.release();
      activityState = null;
    }
  }

  public static String[] getMimeTypes(final ArrayList<String> allowedExtensions) {

    if (allowedExtensions == null || allowedExtensions.isEmpty()) {
        return null;
    }

    final ArrayList<String> mimes = new ArrayList<>();

    for (int i = 0; i < allowedExtensions.size(); i++) {
        final String mime = MimeTypeMap.getSingleton().getMimeTypeFromExtension(allowedExtensions.get(i));
        if (mime == null) {
            continue;
        }

        mimes.add(mime);
    }
    return mimes.toArray(new String[0]);
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result rawResult) {
    if (activityState == null || activityState.getActivity() == null) {
      rawResult.error("no_activity", "file_selector plugin requires a foreground activity.", null);
      return;
    }

    final HashMap arguments = (HashMap) call.arguments;

    MethodChannel.Result result = new MethodResultWrapper(rawResult);
    FileSelectorDelegate delegate = activityState.getDelegate();
    switch (call.method) {
      case METHOD_GET_DIRECTORY_PATH:
        delegate.getDirectoryPath(call, result);
        break;
      case METHOD_GET_SAVE_PATH:
        throw new UnsupportedOperationException("getSavePath is not supported yet");
      case METHOD_OPEN_FILE:
        mimeTypes = getMimeTypes(arguments);
        isMultipleSelection = (boolean) arguments.get("multiple");
        delegate.openFile(call, result, isMultipleSelection, mimeTypes);
        break;
      default:
        throw new IllegalArgumentException("Unknown method " + call.method);
    }
  }

  private String[] getMimeTypes(HashMap arguments) {
    ArrayList acceptedTypeGroups = (ArrayList) arguments.get("acceptedTypeGroups");
    HashMap xTypeGroups = (HashMap) acceptedTypeGroups.get(0);
    ArrayList<String> mimeTypesList = (ArrayList<String>) xTypeGroups.get("mimeTypes");

    return mimeTypesList.toArray(new String[0]);
  }
}
