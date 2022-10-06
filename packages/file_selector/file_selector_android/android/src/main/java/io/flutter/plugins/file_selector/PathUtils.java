// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import android.content.ContentUris;
import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Environment;
import android.provider.DocumentsContract;
import android.provider.MediaStore;
import android.provider.OpenableColumns;
import android.text.TextUtils;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.annotation.VisibleForTesting;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;

@VisibleForTesting
public class PathUtils {

  @VisibleForTesting static String cacheFolder = "file_selector";
  static final String externalStorageDocuments = "com.android.externalstorage.documents";
  static final String providersDownloadsDocuments = "com.android.providers.downloads.documents";
  static final String providersMediaDocuments = "com.android.providers.media.documents";
  /**
   * Given a projection, returns the file name for the uri using the content resolver to avoid
   * unwanted parsing.
   */
  public static String getFileName(Uri uri, @NonNull Context context, String[] projection) {
    Cursor returnCursor = context.getContentResolver().query(uri, projection, null, null, null);

    int nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
    returnCursor.moveToFirst();
    String name = returnCursor.getString(nameIndex);
    returnCursor.close();
    return name;
  }

  @VisibleForTesting
  ArrayList<String> copyFilesToInternalStorage(ArrayList<Uri> uri, Context context) {
    return copyFilesToInternalStorage(uri, context, "");
  }

  private static String copyFileToInternalStorage(Uri uri, Context context, String cacheFolder) {
    ArrayList<Uri> uris = new ArrayList<Uri>() {};
    uris.add(uri);
    ArrayList<String> file = copyFilesToInternalStorage(uris, context, cacheFolder);

    return file.get(0);
  }

  @NonNull
  public static ArrayList<String> copyFilesToInternalStorage(
      ArrayList<Uri> uris, Context context, String cacheFolderName) {
    ArrayList<String> absolutePaths = new ArrayList<>();

    String newDirPath = context.getFilesDir() + "/" + cacheFolderName;
    createDirectoryIfNotExists(newDirPath);

    for (Uri uri : uris) {
      String name =
          getFileName(
              uri, context, new String[] {OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE});
      File output = getFile(context, newDirPath, uri, name);
      absolutePaths.add(output.getAbsolutePath());
    }

    return absolutePaths;
  }

  private static File getFile(Context context, String newDirPath, Uri uri, String name) {
    File output;
    output = new File(newDirPath + "/" + name);
    try {
      InputStream inputStream = context.getContentResolver().openInputStream(uri);
      FileOutputStream outputStream = new FileOutputStream(output);
      int read;
      int bufferSize = 1024;
      final byte[] buffers = new byte[bufferSize];
      while ((read = inputStream.read(buffers)) != -1) {
        outputStream.write(buffers, 0, read);
      }

      inputStream.close();
      outputStream.close();

    } catch (Exception e) {
      System.out.println("There was an error adding a file to the application cache");
    }
    return output;
  }

  private static void createDirectoryIfNotExists(String newDirPath) {
    File dir = new File(newDirPath);
    if (!dir.exists()) {
      dir.mkdir();
    }
  }

  /**
   * Returns an absolute path for the file to be saved from the 3 possible content paths to return.
   * If none of these match, then we will create a copy of the created file in the internal storage
   * and return that path.
   */
  @VisibleForTesting
  @Nullable
  public static String getSavePathUri(final Uri uri, Context context) {
    final String docId = DocumentsContract.getDocumentId(uri);

    if (docId.isEmpty()) {
      return null;
    }

    switch (uri.getAuthority()) {
      case externalStorageDocuments:
        final String[] split = docId.split(":");
        return getPathFromExtSD(uri, context, split);
      case providersDownloadsDocuments:
        return getDownloadsDocumentPath(uri, context, docId);
      case providersMediaDocuments:
        return getMediaDocumentDataColumn(context, docId);
    }

    if (uri.getScheme().equalsIgnoreCase("content")) {
      if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
        return copyFileToInternalStorage(uri, context, cacheFolder);
      } else {
        return getDataColumn(context, uri, null, null);
      }
    } else if (uri.getScheme().equalsIgnoreCase("file")) {
      return uri.getPath();
    }

    return null;
  }

  @Nullable
  private static String getDownloadsDocumentPath(Uri uri, Context context, String docId) {
    String fileName =
        getFileName(uri, context, new String[] {MediaStore.MediaColumns.DISPLAY_NAME});
    String path = Environment.getExternalStorageDirectory().toString() + "/Download/" + fileName;
    if (!TextUtils.isEmpty(path)) {
      return path;
    }

    if (docId.startsWith("raw:")) {
      return docId.replaceFirst("raw:", "");
    }
    String[] contentUriPrefixesToTry =
        new String[] {"content://downloads/public_downloads", "content://downloads/my_downloads"};
    for (String contentUriPrefix : contentUriPrefixesToTry) {
      try {
        final Uri contentUri =
            ContentUris.withAppendedId(Uri.parse(contentUriPrefix), Long.parseLong(docId));

        return getDataColumn(context, contentUri, null, null);
      } catch (NumberFormatException e) {
        //In Android 8 and Android P the id is not a number
        return uri.getPath().replaceFirst("^/document/raw:", "").replaceFirst("^raw:", "");
      }
    }

    return null;
  }

  @Nullable
  private static String getMediaDocumentDataColumn(Context context, String docId) {
    String selection;
    String[] selectionArgs;
    final String[] split = docId.split(":");
    final String type = split[0];

    Uri contentUri = null;

    switch (type) {
      case "image":
        contentUri = MediaStore.Images.Media.EXTERNAL_CONTENT_URI;
        break;
      case "video":
        contentUri = MediaStore.Video.Media.EXTERNAL_CONTENT_URI;
        break;
      case "audio":
        contentUri = MediaStore.Audio.Media.EXTERNAL_CONTENT_URI;
        break;
    }
    selection = "_id=?";
    selectionArgs = new String[] {split[1]};

    if (contentUri != null) {
      return contentUri + "/" + getDataColumn(context, contentUri, selection, selectionArgs);
    }

    return null;
  }

  @VisibleForTesting
  static boolean fileExists(String filePath) {
    File file = new File(filePath);
    return file.exists();
  }

  @Nullable
  private static String getPathFromExtSD(Uri uri, Context context, @NonNull String[] pathData) {
    final String type = pathData[0];
    final String relativePath = "/" + pathData[1] + "/";
    String fullPath;
    String fileName =
        getFileName(uri, context, new String[] {MediaStore.MediaColumns.DISPLAY_NAME});

    if (type.equalsIgnoreCase("primary")) {
      fullPath = Environment.getExternalStorageDirectory() + relativePath + fileName;
      if (fileExists(fullPath)) {
        return fullPath;
      }
    }

    // Environment.isExternalStorageRemovable() is `true` for external and internal storage
    // so we cannot relay on it.
    //
    // instead, for each possible path, check if file exists
    // we'll start with secondary storage as this could be our (physically) removable sd card
    fullPath = System.getenv("SECONDARY_STORAGE") + relativePath;
    if (fileExists(fullPath)) {
      return fullPath;
    }

    fullPath = System.getenv("EXTERNAL_STORAGE") + relativePath;
    if (fileExists(fullPath)) {
      return fullPath;
    }

    return null;
  }

  @Nullable
  private static String getDataColumn(
      @NonNull Context context, Uri uri, String selection, String[] selectionArgs) {
    Cursor cursor = null;
    final String column = "_data";
    final String[] projection = {column};

    try {
      cursor = context.getContentResolver().query(uri, projection, selection, selectionArgs, null);

      if (cursor != null && cursor.moveToFirst()) {
        final int index = cursor.getColumnIndexOrThrow(column);
        return cursor.getString(index);
      }
    } finally {
      if (cursor != null) cursor.close();
    }

    return null;
  }

  @VisibleForTesting
  void clearCache(Context context) {
    clearCache(context, "");
  }

  public static void clearCache(Context context, String cacheFolderName) {
    File cacheDir = new File(context.getFilesDir() + "/" + cacheFolderName + "/");
    File[] files = cacheDir.listFiles();

    if (files != null) {
      for (File file : files) {
        file.delete();
      }
    }
  }
}
