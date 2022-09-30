package io.flutter.plugins.file_selector;

import android.content.Context;
import android.database.Cursor;
import android.net.Uri;
import android.provider.OpenableColumns;
import androidx.annotation.VisibleForTesting;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.HashMap;

@VisibleForTesting
public class PathUtils {

  public static String getFileName(Uri uri, Context context) {
    Cursor returnCursor =
        context
            .getContentResolver()
            .query(
                uri,
                new String[] {OpenableColumns.DISPLAY_NAME, OpenableColumns.SIZE},
                null,
                null,
                null);

    int nameIndex = returnCursor.getColumnIndex(OpenableColumns.DISPLAY_NAME);
    returnCursor.moveToFirst();
    String name = returnCursor.getString(nameIndex);
    returnCursor.close();
    return name;
  }

  @VisibleForTesting
  ArrayList<String> copyFileToInternalStorage(ArrayList<Uri> uri, Context context) {
    return copyFileToInternalStorage(uri, context, "");
  }

  public static ArrayList<String> copyFileToInternalStorage(ArrayList<Uri> uris, Context context, String cacheFolderName) {
    ArrayList<String> absolutePaths = null;
    String newDirPath = context.getFilesDir() + "/" + cacheFolderName;
    for(Uri uri : uris){
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
      absolutePaths.add(output.getAbsolutePath());
    }

    return absolutePaths;
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
