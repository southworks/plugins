// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.
// Autogenerated from Pigeon (v3.2.9), do not edit directly.
// See also: https://pub.dev/packages/pigeon

package io.flutter.plugins.file_selector;

import android.util.Log;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import io.flutter.plugin.common.BasicMessageChannel;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MessageCodec;
import io.flutter.plugin.common.StandardMessageCodec;
import java.io.ByteArrayOutputStream;
import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

/** Generated class from Pigeon. */
@SuppressWarnings({"unused", "unchecked", "CodeBlock2Expr", "RedundantSuppression"})
public class Messages {

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class SelectionOptions {
    private @NonNull Boolean allowMultiple;
    public @NonNull Boolean getAllowMultiple() { return allowMultiple; }
    public void setAllowMultiple(@NonNull Boolean setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"allowMultiple\" is null.");
      }
      this.allowMultiple = setterArg;
    }

    private @NonNull List<String> allowedTypes;
    public @NonNull List<String> getAllowedTypes() { return allowedTypes; }
    public void setAllowedTypes(@NonNull List<String> setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"allowedTypes\" is null.");
      }
      this.allowedTypes = setterArg;
    }

    /** Constructor is private to enforce null safety; use Builder. */
    private SelectionOptions() {}
    public static final class Builder {
      private @Nullable Boolean allowMultiple;
      public @NonNull Builder setAllowMultiple(@NonNull Boolean setterArg) {
        this.allowMultiple = setterArg;
        return this;
      }
      private @Nullable List<String> allowedTypes;
      public @NonNull Builder setAllowedTypes(@NonNull List<String> setterArg) {
        this.allowedTypes = setterArg;
        return this;
      }
      public @NonNull SelectionOptions build() {
        SelectionOptions pigeonReturn = new SelectionOptions();
        pigeonReturn.setAllowMultiple(allowMultiple);
        pigeonReturn.setAllowedTypes(allowedTypes);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("allowMultiple", allowMultiple);
      toMapResult.put("allowedTypes", allowedTypes);
      return toMapResult;
    }
    static @NonNull SelectionOptions fromMap(@NonNull Map<String, Object> map) {
      SelectionOptions pigeonResult = new SelectionOptions();
      Object allowMultiple = map.get("allowMultiple");
      pigeonResult.setAllowMultiple((Boolean)allowMultiple);
      Object allowedTypes = map.get("allowedTypes");
      pigeonResult.setAllowedTypes((List<String>)allowedTypes);
      return pigeonResult;
    }
  }

  public interface Result<T> {
    void success(T result);
    void error(Throwable error);
  }
  private static class FileSelectorApiCodec extends StandardMessageCodec {
    public static final FileSelectorApiCodec INSTANCE = new FileSelectorApiCodec();
    private FileSelectorApiCodec() {}
    @Override
    protected Object readValueOfType(byte type, ByteBuffer buffer) {
      switch (type) {
        case (byte)128:         
          return SelectionOptions.fromMap((Map<String, Object>) readValue(buffer));
        
        default:        
          return super.readValueOfType(type, buffer);
        
      }
    }
    @Override
    protected void writeValue(ByteArrayOutputStream stream, Object value)     {
      if (value instanceof SelectionOptions) {
        stream.write(128);
        writeValue(stream, ((SelectionOptions) value).toMap());
      } else 
{
        super.writeValue(stream, value);
      }
    }
  }

  /** Generated interface from Pigeon that represents a handler of messages from Flutter.*/
  public interface FileSelectorApi {
    void openFiles(@NonNull SelectionOptions options, Result<List<String>> result);
    void getDirectoryPath(@Nullable String initialDirectory, Result<String> result);

    /** The codec used by FileSelectorApi. */
    static MessageCodec<Object> getCodec() {
      return FileSelectorApiCodec.INSTANCE;
    }

    /** Sets up an instance of `FileSelectorApi` to handle messages through the `binaryMessenger`. */
    static void setup(BinaryMessenger binaryMessenger, FileSelectorApi api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openFiles", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              SelectionOptions optionsArg = (SelectionOptions)args.get(0);
              if (optionsArg == null) {
                throw new NullPointerException("optionsArg unexpectedly null.");
              }
              Result<List<String>> resultCallback = new Result<List<String>>() {
                public void success(List<String> result) {
                  wrapped.put("result", result);
                  reply.reply(wrapped);
                }
                public void error(Throwable error) {
                  wrapped.put("error", wrapError(error));
                  reply.reply(wrapped);
                }
              };

              api.openFiles(optionsArg, resultCallback);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
              reply.reply(wrapped);
            }
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.getDirectoryPath", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              String initialDirectoryArg = (String)args.get(0);
              Result<String> resultCallback = new Result<String>() {
                public void success(String result) {
                  wrapped.put("result", result);
                  reply.reply(wrapped);
                }
                public void error(Throwable error) {
                  wrapped.put("error", wrapError(error));
                  reply.reply(wrapped);
                }
              };

              api.getDirectoryPath(initialDirectoryArg, resultCallback);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
              reply.reply(wrapped);
            }
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
    }
  }
  private static Map<String, Object> wrapError(Throwable exception) {
    Map<String, Object> errorMap = new HashMap<>();
    errorMap.put("message", exception.toString());
    errorMap.put("code", exception.getClass().getSimpleName());
    errorMap.put("details", "Cause: " + exception.getCause() + ", Stacktrace: " + Log.getStackTraceString(exception));
    return errorMap;
  }
}
