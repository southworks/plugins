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
import android.database.Cursor;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.File;
import android.app.Activity;

public class PathUtils {
    static final String cachePath = "file_selector";

    public static String getFileName(Uri uri, final Context context) {
        String result = null;

        Cursor returnCursor = context.getContentResolver().query(uri, new String[] {
            OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE
        }, null, null, null);

        int nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
        returnCursor.moveToFirst();

        return (returnCursor.getString(nameIndex));
    }

    public static String copyFileToInternalStorage(Uri uri, final Context context) {
        String newDirPath = context.getFilesDir() + "/" + cachePath;
        String name = getFileName(uri, context);

        File output;
        File dir = new File(newDirPath);
        if (!dir.exists()) {
          dir.mkdir();
        }
        output = new File(newDirPath + "/" + name);
        try {
          InputStream inputStream = context.getContentResolver().openInputStream(uri);
          FileOutputStream outputStream = new FileOutputStream(output);
          int read = 0;
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

        return output.getAbsolutePath();
      }

    public static boolean clearCache(final Context context) {
        try {
            final File cacheDir = new File(context.getFilesDir() + "/" + cachePath + "/");
            final File[] files = cacheDir.listFiles();

            if (files != null) {
                for (final File file : files) {
                    file.delete();
                }
            }
        } catch (final Exception ex) {
            System.out.println("There was an error clearing the app cache");
            return false;
        }
        return true;
    }
}