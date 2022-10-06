// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static android.provider.DocumentsContract.EXTRA_INITIAL_URI;

import android.app.Activity;
import android.content.ClipData;
import android.content.Intent;
import android.net.Uri;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;
import java.util.ArrayList;
import java.util.HashMap;

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
  @VisibleForTesting static final int REQUEST_CODE_GET_SAVE_PATH = 2344;
  @VisibleForTesting static final int REQUEST_CODE_OPEN_FILE = 2343;

  /** Constants for key types in the dart invoke methods */
  @VisibleForTesting static final String _confirmButtonText = "confirmButtonText";

  @VisibleForTesting static final String _initialDirectory = "initialDirectory";
  @VisibleForTesting static final String _suggestedNameKey = "suggestedName";
  @VisibleForTesting static final String _acceptedTypeGroups = "acceptedTypeGroups";
  @VisibleForTesting static final String _multiple = "multiple";
  @VisibleForTesting static String cacheFolder = "file_selector";

  @VisibleForTesting Intent openFileIntent = new Intent();

  private MethodChannel.Result pendingResult;
  private final Activity activity;

  @Override
  public boolean onRequestPermissionsResult(
      int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
    return true;
  }

  public FileSelectorDelegate(final Activity activity) {
    this(activity, null, null);
  }

  /**
   * These constructors are used exclusively for testing; they can be used to provide mocks to final
   * fields of this class. Otherwise, those fields would have to be mutable and visible.
   */
  @VisibleForTesting
  FileSelectorDelegate() {
    this(null, null, null);
  }

  @VisibleForTesting
  FileSelectorDelegate(
      final Activity activity, final MethodChannel.Result result, final MethodCall methodCall) {
    this.activity = activity;
    this.pendingResult = result;
  }

  @VisibleForTesting
  public void clearCache() {
    PathUtils.clearCache(this.activity, cacheFolder);
  }

  public void getDirectoryPath(MethodCall methodCall, MethodChannel.Result result) {
    if (setPendingResult(result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    launchGetDirectoryPath(methodCall.argument(_initialDirectory));
  }

  public void getSavePath(MethodCall methodCall, MethodChannel.Result result) {
    if (setPendingResult(result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    String initialDirectory = methodCall.argument(_initialDirectory);
    String suggestedName = methodCall.argument(_suggestedNameKey);

    launchGetSavePath(initialDirectory, suggestedName);
  }

  public void openFile(MethodCall methodCall, MethodChannel.Result result) {
    if (setPendingResult(result)) {
      finishWithAlreadyActiveError(result);
      return;
    }

    Boolean multipleFiles = methodCall.argument(_multiple);
    ArrayList acceptedTypeGroups = methodCall.argument(_acceptedTypeGroups);

    launchOpenFile(multipleFiles, acceptedTypeGroups);
  }

  @VisibleForTesting
  void launchGetDirectoryPath(@Nullable String initialDirectory) {
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

  @VisibleForTesting
  void launchGetSavePath(@Nullable String initialDirectory, @Nullable String suggestedName) {
    Intent getSavePathIntent = new Intent(Intent.ACTION_CREATE_DOCUMENT);
    getSavePathIntent.setType("*/*");

    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O
        && initialDirectory != null
        && !initialDirectory.isEmpty()) {
      Uri uri = getSavePathIntent.getParcelableExtra(EXTRA_INITIAL_URI);
      String scheme = uri.toString();
      scheme = scheme.replace("/root/", initialDirectory);
      uri = Uri.parse(scheme);
      getSavePathIntent.putExtra(EXTRA_INITIAL_URI, uri);
    }

    if (suggestedName != null && !suggestedName.isEmpty()) {
      getSavePathIntent.putExtra(Intent.EXTRA_TITLE, suggestedName);
    }

    activity.startActivityForResult(getSavePathIntent, REQUEST_CODE_GET_SAVE_PATH);
  }

  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    switch (requestCode) {
      case REQUEST_CODE_GET_DIRECTORY_PATH:
        handleGetDirectoryPathResult(resultCode, data);
        break;
      case REQUEST_CODE_GET_SAVE_PATH:
        handleGetSavePathResult(resultCode, data);
        break;
      case REQUEST_CODE_OPEN_FILE:
        handleOpenFileResult(resultCode, data);
        break;
      default:
        return false;
    }

    return true;
  }

  void launchOpenFile(boolean isMultipleSelection, ArrayList acceptedTypeGroups) {
    openFileIntent.setAction(Intent.ACTION_GET_CONTENT);
    openFileIntent.addCategory(Intent.CATEGORY_OPENABLE);
    openFileIntent.putExtra(Intent.EXTRA_ALLOW_MULTIPLE, isMultipleSelection);
    openFileIntent.setType("*/*");

    if (acceptedTypeGroups != null && !acceptedTypeGroups.isEmpty()) {
      String[] mimeTypes = getMimeTypes(acceptedTypeGroups);

      if (mimeTypes.length > 0) {
        openFileIntent.putExtra(Intent.EXTRA_MIME_TYPES, mimeTypes);
      }
    }

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

  @VisibleForTesting
  void handleGetSavePathResult(int resultCode, Intent data) {
    if (resultCode == Activity.RESULT_OK && data != null) {
      Uri path = data.getData();
      String fullPath = PathUtils.getSavePathUri(path, this.activity);

      handleGetSavePathResult(fullPath);
      return;
    }

    finishWithSuccess(null);
  }

  void handleOpenFileResult(int resultCode, Intent data) {
    if (resultCode != Activity.RESULT_OK || data == null) {
      finishWithSuccess(null);
      return;
    }

    ArrayList<Uri> uris = uriHandler(data);

    ArrayList<String> srcPaths =
        PathUtils.copyFilesToInternalStorage(uris, this.activity, cacheFolder);
    handleOpenFileActionResults(srcPaths);
  }

  private void handleGetDirectoryPathResult(String path) {
    finishWithSuccess(path);
  }

  private void handleGetSavePathResult(String path) {
    finishWithSuccess(path);
  }

  @VisibleForTesting
  void handleOpenFileActionResults(ArrayList<String> srcPaths) {
    finishWithListSuccess(srcPaths);
  }

  private boolean setPendingResult(MethodChannel.Result result) {
    if (pendingResult != null) {
      return true;
    }

    pendingResult = result;

    return false;
  }

  private void finishWithSuccess(String srcPath) {
    pendingResult.success(srcPath);
    clearMethodCallAndResult();
  }

  @VisibleForTesting
  void finishWithListSuccess(ArrayList<String> srcPaths) {
    if (pendingResult == null) {
      return;
    }
    pendingResult.success(srcPaths);
    clearMethodCallAndResult();
  }

  private void finishWithAlreadyActiveError(@NonNull MethodChannel.Result result) {
    result.error("already_active", "File selector is already active", null);
  }

  private void finishWithError(String errorCode, String errorMessage) {
    pendingResult.error(errorCode, errorMessage, null);
    clearMethodCallAndResult();
  }

  @VisibleForTesting
  void clearMethodCallAndResult() {
    pendingResult = null;
  }

  @VisibleForTesting
  String[] getMimeTypes(ArrayList acceptedTypeGroups) {
    ArrayList<String> mimeTypesList = new ArrayList<>();
    for (Object acceptedType : acceptedTypeGroups) {
      HashMap xTypeGroup = (HashMap) acceptedType;
      ArrayList<String> types = (ArrayList<String>) xTypeGroup.get("mimeTypes");
      if (types != null) mimeTypesList.addAll(types);
    }
    return mimeTypesList.toArray(new String[0]);
  }

  @VisibleForTesting
  ArrayList<Uri> uriHandler(Intent data) {
    ArrayList<Uri> uris = new ArrayList<>();
    ClipData clipData = data.getClipData();
    if (clipData != null) {
      int itemCount = clipData.getItemCount();
      for (int i = 0; i < itemCount; i++) {
        uris.add(clipData.getItemAt(i).getUri());
      }
    } else {
      uris.add(data.getData());
    }
    return uris;
  }
}
