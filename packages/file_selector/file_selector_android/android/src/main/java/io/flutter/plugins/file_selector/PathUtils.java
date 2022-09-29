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
import android.util.Log;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;

public class PathUtils {
    private static Uri contentUri = null;

    @Nullable
    public static String getPath(final Uri uri, Context context) {
        String selection;
        String[] selectionArgs;
        final String docId = DocumentsContract.getDocumentId(uri);

        if (isExternalStorageDocument(uri)) {
            final String[] split = docId.split(":");

            String fullPath = getPathFromExtSD(split);
            if (!fullPath.isEmpty()) {
                return fullPath;
            } else {
                return null;
            }
        }

        if (isDownloadsDocument(uri)) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                try (Cursor cursor = context.getContentResolver().query(uri, new String[]{MediaStore.MediaColumns.DISPLAY_NAME}, null, null, null)) {
                    if (cursor != null && cursor.moveToFirst()) {
                        String fileName = cursor.getString(0);
                        String path = Environment.getExternalStorageDirectory().toString() + "/Download/" + fileName;
                        if (!TextUtils.isEmpty(path)) {
                            return path;
                        }
                    }
                }
                if (!TextUtils.isEmpty(docId)) {
                    if (docId.startsWith("raw:")) {
                        return docId.replaceFirst("raw:", "");
                    }
                    String[] contentUriPrefixesToTry = new String[]{
                            "content://downloads/public_downloads",
                            "content://downloads/my_downloads"
                    };
                    for (String contentUriPrefix : contentUriPrefixesToTry) {
                        try {
                            final Uri contentUri = ContentUris.withAppendedId(Uri.parse(contentUriPrefix), Long.parseLong(docId));

                            return getDataColumn(context, contentUri, null, null);
                        } catch (NumberFormatException e) {
                            //In Android 8 and Android P the id is not a number
                            return uri.getPath().replaceFirst("^/document/raw:", "").replaceFirst("^raw:", "");
                        }
                    }


                }
            }
            else {
                final String id = DocumentsContract.getDocumentId(uri);

                if (id.startsWith("raw:")) {
                    return id.replaceFirst("raw:", "");
                }

                try {
                    contentUri = ContentUris.withAppendedId(
                            Uri.parse("content://downloads/public_downloads"), Long.parseLong(id));
                }
                catch (NumberFormatException e) {
                    e.printStackTrace();
                }
                if (contentUri != null) {
                    return getDataColumn(context, contentUri, null, null);
                }
            }
        }

        // MediaProvider
        if (isMediaDocument(uri)) {
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
            selectionArgs = new String[]{split[1]};

            return getDataColumn(context, contentUri, selection,
                    selectionArgs);
        }

        if ("content".equalsIgnoreCase(uri.getScheme())) {
            if( Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q)
            {
                return copyFileToInternalStorage(uri,context);
            }
            else
            {
                return getDataColumn(context, uri, null, null);
            }
        }
        if ("file".equalsIgnoreCase(uri.getScheme())) {
            return uri.getPath();
        }

        return null;
    }

    private static boolean fileExists(String filePath) {
        File file = new File(filePath);

        return file.exists();
    }

    @NonNull
    private static String getPathFromExtSD(@NonNull String[] pathData) {
        final String type = pathData[0];
        final String relativePath = "/" + pathData[1];
        String fullPath;

        if ("primary".equalsIgnoreCase(type)) {
            fullPath = Environment.getExternalStorageDirectory() + relativePath;
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
        fileExists(fullPath);

        return fullPath;
    }

    @NonNull
    private static String copyFileToInternalStorage(Uri uri, @NonNull Context context) {
        Cursor returnCursor = context.getContentResolver().query(uri, new String[]{
                OpenableColumns.DISPLAY_NAME,OpenableColumns.SIZE
        }, null, null, null);

        int nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
        returnCursor.moveToFirst();
        String name = (returnCursor.getString(nameIndex));

        File output;
        output = new File(context.getFilesDir() + "/" + name);

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
            returnCursor.close();
        }
        catch (Exception e) {
            Log.e("Exception", e.getMessage());
        }

        return output.getPath();
    }

    @Nullable
    private static String getDataColumn(@NonNull Context context, Uri uri, String selection, String[] selectionArgs) {
        Cursor cursor = null;
        final String column = "_data";
        final String[] projection = {column};

        try {
            cursor = context.getContentResolver().query(uri, projection,
                    selection, selectionArgs, null);

            if (cursor != null && cursor.moveToFirst()) {
                final int index = cursor.getColumnIndexOrThrow(column);
                return cursor.getString(index);
            }
        }
        finally {
            if (cursor != null)
                cursor.close();
        }

        return null;
    }

    private static boolean isExternalStorageDocument(@NonNull Uri uri) {
        return "com.android.externalstorage.documents".equals(uri.getAuthority());
    }

    private static boolean isDownloadsDocument(@NonNull Uri uri) {
        return "com.android.providers.downloads.documents".equals(uri.getAuthority());
    }

    private static boolean isMediaDocument(@NonNull Uri uri) {
        return "com.android.providers.media.documents".equals(uri.getAuthority());
    }
}