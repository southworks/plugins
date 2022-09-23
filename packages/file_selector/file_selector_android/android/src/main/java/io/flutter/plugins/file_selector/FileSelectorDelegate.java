// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.RequiresApi;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.util.ArrayList;
import java.util.Arrays;
import android.os.Environment;
import android.net.Uri;
import android.provider.DocumentsContract;

/**
 * A delegate class doing the heavy lifting for the plugin.
 *
 * <p>When invoked, all the "access file" methods go through the same steps:
 *
 * <p>1. Check for an existing {@link #pendingResult}. If a previous pendingResult exists, this
 * means that the method was called at least twice. In this case, stop executing and finish with an
 * error.
 *
 * <p>3. Launch the file explorer.
 *
 * <p>This can end up in two different outcomes:
 *
 * <p>A) User picks a file or directory.
 *
 * <p>B) User cancels picking a file or directory. Finish with null result.
 */
public class FileSelectorDelegate
    implements PluginRegistry.ActivityResultListener,
        PluginRegistry.RequestPermissionsResultListener {
  @VisibleForTesting static final int REQUEST_CODE_GET_DIRECTORY_PATH = 2342;
  @VisibleForTesting static final int REQUEST_CODE_OPEN_FILE = 2343;

  /** Constants for key types in the dart invoke methods */
  @VisibleForTesting static final String _confirmButtonText = "confirmButtonText";

  @VisibleForTesting static final String _initialDirectory = "initialDirectory";

  private final Activity activity;

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    return true;
  }

  private MethodChannel.Result pendingResult;
  private MethodCall methodCall;

  public FileSelectorDelegate(final Activity activity) {
    this(activity, null, null);
  }

  /**
   * This constructor is used exclusively for testing; it can be used to provide mocks to final
   * fields of this class. Otherwise those fields would have to be mutable and visible.
   */
  @VisibleForTesting
  FileSelectorDelegate(
      final Activity activity, final MethodChannel.Result result, final MethodCall methodCall) {
    this.activity = activity;
    this.pendingResult = result;
    this.methodCall = methodCall;
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  public void getDirectoryPath(MethodCall methodCall, MethodChannel.Result result) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    launchGetDirectoryPath(methodCall.argument(_initialDirectory));
  }

  public void openFile(MethodCall methodCall, MethodChannel.Result result, boolean isMultipleSelection, String[] mimeTypes) {
    if (!setPendingMethodCallAndResult(methodCall, result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    launchOpenFile(isMultipleSelection, mimeTypes);
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode) {
      case REQUEST_CODE_GET_DIRECTORY_PATH:
        handleGetDirectoryPathResult(resultCode, data);
        break;
      case REQUEST_CODE_OPEN_FILE:
        handleOpenFileResult(resultCode, data);
        break;
      default:
        return false;
    }

    return true;
  }

  @RequiresApi(api = Build.VERSION_CODES.LOLLIPOP)
  private void launchGetDirectoryPath(@Nullable String initialDirectory) {
    Intent getDirectoryPathIntent = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);

    if (initialDirectory != null && !initialDirectory.isEmpty()) {
      Uri uri = getDirectoryPathIntent.getParcelableExtra("android.provider.extra.INITIAL_URI");
      String scheme = uri.toString();
      scheme = scheme.replace("/root/", initialDirectory);
      uri = Uri.parse(scheme);
      getDirectoryPathIntent.putExtra("android.provider.extra.INITIAL_URI", uri);
    }
    activity.startActivityForResult(getDirectoryPathIntent, REQUEST_CODE_GET_DIRECTORY_PATH);
  }

  private void launchOpenFile(boolean isMultipleSelection, String[] mimeTypes) {
    Intent openFileIntent = new Intent(Intent.ACTION_GET_CONTENT);
    openFileIntent.addCategory(Intent.CATEGORY_OPENABLE);
    openFileIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION);
    openFileIntent.setType(mimeTypes.length == 1 ? mimeTypes[0] : "*/*");

    if (mimeTypes.length > 0) {
      openFileIntent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
    }

    openFileIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, isMultipleSelection);

    activity.startActivityForResult(openFileIntent, REQUEST_CODE_OPEN_FILE);
  }

  private void handleGetDirectoryPathResult(int resultCode, Intent data) {
    if (resultCode == Activity.RESULT_OK && data != null) {
      Uri path = data.getData();
      handleGetDirectoryPathResult(path.toString());
      return;
    }

    finishWithSuccess(null);
  }

  private void handleOpenFileResult(int resultCode, Intent data) {
    if (resultCode == Activity.RESULT_OK && data != null) {
      ArrayList<String> srcPaths = new ArrayList<>(Arrays.asList(data.getData().toString()));
      //ArrayList<String> srcPaths = new ArrayList<>(Arrays.asList("file://com.android.providers.downloads.documents/document/sample3.txt"));
      //ArrayList<String> srcPaths = new ArrayList<>(Arrays.asList("content://com.android.providers.downloads.documents/document/msf:24.txt"));

      handleActionResults(srcPaths);
      return;
    }

    finishWithSuccess(null);
  }

  private void handleGetDirectoryPathResult(String path) {
    finishWithSuccess(path);
  }

  private void handleActionResults(ArrayList<String> srcPaths) {
    finishWithListSuccess(srcPaths);
  }


  private boolean setPendingMethodCallAndResult(
      MethodCall methodCall, MethodChannel.Result result) {
    if (pendingResult != null) {
      return false;
    }

    this.methodCall = methodCall;
    pendingResult = result;

    return true;
  }

  private void finishWithSuccess(String srcPath) {
    pendingResult.success(srcPath);
    clearMethodCallAndResult();
  }

  private void finishWithListSuccess(ArrayList<String> srcPaths) {
    if (pendingResult == null) {
      return;
    }
    pendingResult.success(srcPaths);
    clearMethodCallAndResult();
  }

  private void finishWithAlreadyActiveError(MethodChannel.Result result) {
    result.error("already_active", "File selector is already active", null);
  }

  private void finishWithError(String errorCode, String errorMessage) {
    pendingResult.error(errorCode, errorMessage, null);
    clearMethodCallAndResult();
  }

  private void clearMethodCallAndResult() {
    methodCall = null;
    pendingResult = null;
  }
}
