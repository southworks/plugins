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

  public enum FileSelectorMethod {
    OPEN_FILE(0),
    GET_DIRECTORY_PATH(1),
    OPEN_MULTIPLE_FILES(2);

    private int index;
    private FileSelectorMethod(final int index) {
      this.index = index;
    }
  }

  /** Generated class from Pigeon that represents data sent in messages. */
  public static class TypeGroup {
    private @NonNull String label;
    public @NonNull String getLabel() { return label; }
    public void setLabel(@NonNull String setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"label\" is null.");
      }
      this.label = setterArg;
    }

    private @NonNull List<String> extensions;
    public @NonNull List<String> getExtensions() { return extensions; }
    public void setExtensions(@NonNull List<String> setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"extensions\" is null.");
      }
      this.extensions = setterArg;
    }

    /** Constructor is private to enforce null safety; use Builder. */
    private TypeGroup() {}
    public static final class Builder {
      private @Nullable String label;
      public @NonNull Builder setLabel(@NonNull String setterArg) {
        this.label = setterArg;
        return this;
      }
      private @Nullable List<String> extensions;
      public @NonNull Builder setExtensions(@NonNull List<String> setterArg) {
        this.extensions = setterArg;
        return this;
      }
      public @NonNull TypeGroup build() {
        TypeGroup pigeonReturn = new TypeGroup();
        pigeonReturn.setLabel(label);
        pigeonReturn.setExtensions(extensions);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("label", label);
      toMapResult.put("extensions", extensions);
      return toMapResult;
    }
    static @NonNull TypeGroup fromMap(@NonNull Map<String, Object> map) {
      TypeGroup pigeonResult = new TypeGroup();
      Object label = map.get("label");
      pigeonResult.setLabel((String)label);
      Object extensions = map.get("extensions");
      pigeonResult.setExtensions((List<String>)extensions);
      return pigeonResult;
    }
  }

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

    private @NonNull Boolean selectFolders;
    public @NonNull Boolean getSelectFolders() { return selectFolders; }
    public void setSelectFolders(@NonNull Boolean setterArg) {
      if (setterArg == null) {
        throw new IllegalStateException("Nonnull field \"selectFolders\" is null.");
      }
      this.selectFolders = setterArg;
    }

    private @NonNull List<TypeGroup> allowedTypes;
    public @NonNull List<TypeGroup> getAllowedTypes() { return allowedTypes; }
    public void setAllowedTypes(@NonNull List<TypeGroup> setterArg) {
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
      private @Nullable Boolean selectFolders;
      public @NonNull Builder setSelectFolders(@NonNull Boolean setterArg) {
        this.selectFolders = setterArg;
        return this;
      }
      private @Nullable List<TypeGroup> allowedTypes;
      public @NonNull Builder setAllowedTypes(@NonNull List<TypeGroup> setterArg) {
        this.allowedTypes = setterArg;
        return this;
      }
      public @NonNull SelectionOptions build() {
        SelectionOptions pigeonReturn = new SelectionOptions();
        pigeonReturn.setAllowMultiple(allowMultiple);
        pigeonReturn.setSelectFolders(selectFolders);
        pigeonReturn.setAllowedTypes(allowedTypes);
        return pigeonReturn;
      }
    }
    @NonNull Map<String, Object> toMap() {
      Map<String, Object> toMapResult = new HashMap<>();
      toMapResult.put("allowMultiple", allowMultiple);
      toMapResult.put("selectFolders", selectFolders);
      toMapResult.put("allowedTypes", allowedTypes);
      return toMapResult;
    }
    static @NonNull SelectionOptions fromMap(@NonNull Map<String, Object> map) {
      SelectionOptions pigeonResult = new SelectionOptions();
      Object allowMultiple = map.get("allowMultiple");
      pigeonResult.setAllowMultiple((Boolean)allowMultiple);
      Object selectFolders = map.get("selectFolders");
      pigeonResult.setSelectFolders((Boolean)selectFolders);
      Object allowedTypes = map.get("allowedTypes");
      pigeonResult.setAllowedTypes((List<TypeGroup>)allowedTypes);
      return pigeonResult;
    }
  }
  private static class FileSelectorApiCodec extends StandardMessageCodec {
    public static final FileSelectorApiCodec INSTANCE = new FileSelectorApiCodec();
    private FileSelectorApiCodec() {}
    @Override
    protected Object readValueOfType(byte type, ByteBuffer buffer) {
      switch (type) {
        case (byte)128:         
          return SelectionOptions.fromMap((Map<String, Object>) readValue(buffer));
        
        case (byte)129:         
          return TypeGroup.fromMap((Map<String, Object>) readValue(buffer));
        
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
      if (value instanceof TypeGroup) {
        stream.write(129);
        writeValue(stream, ((TypeGroup) value).toMap());
      } else 
{
        super.writeValue(stream, value);
      }
    }
  }

  /** Generated interface from Pigeon that represents a handler of messages from Flutter.*/
  public interface FileSelectorApi {
    @NonNull List<String> startFileExplorer(@NonNull FileSelectorMethod method, @NonNull SelectionOptions options, @Nullable String initialDirectory, @Nullable String confirmButtonText);
    @Nullable String openSaveDialog(@NonNull SelectionOptions options, @Nullable String initialDirectory, @Nullable String confirmButtonText, @Nullable String suggestedName);

    /** The codec used by FileSelectorApi. */
    static MessageCodec<Object> getCodec() {
      return FileSelectorApiCodec.INSTANCE;
    }

    /** Sets up an instance of `FileSelectorApi` to handle messages through the `binaryMessenger`. */
    static void setup(BinaryMessenger binaryMessenger, FileSelectorApi api) {
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.startFileExplorer", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              FileSelectorMethod methodArg = args.get(0) == null ? null : FileSelectorMethod.values()[(int)args.get(0)];
              if (methodArg == null) {
                throw new NullPointerException("methodArg unexpectedly null.");
              }
              SelectionOptions optionsArg = (SelectionOptions)args.get(1);
              if (optionsArg == null) {
                throw new NullPointerException("optionsArg unexpectedly null.");
              }
              String initialDirectoryArg = (String)args.get(2);
              String confirmButtonTextArg = (String)args.get(3);
              List<String> output = api.startFileExplorer(methodArg, optionsArg, initialDirectoryArg, confirmButtonTextArg);
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
          });
        } else {
          channel.setMessageHandler(null);
        }
      }
      {
        BasicMessageChannel<Object> channel =
            new BasicMessageChannel<>(binaryMessenger, "dev.flutter.pigeon.FileSelectorApi.openSaveDialog", getCodec());
        if (api != null) {
          channel.setMessageHandler((message, reply) -> {
            Map<String, Object> wrapped = new HashMap<>();
            try {
              ArrayList<Object> args = (ArrayList<Object>)message;
              SelectionOptions optionsArg = (SelectionOptions)args.get(0);
              if (optionsArg == null) {
                throw new NullPointerException("optionsArg unexpectedly null.");
              }
              String initialDirectoryArg = (String)args.get(1);
              String confirmButtonTextArg = (String)args.get(2);
              String suggestedNameArg = (String)args.get(3);
              String output = api.openSaveDialog(optionsArg, initialDirectoryArg, confirmButtonTextArg, suggestedNameArg);
              wrapped.put("result", output);
            }
            catch (Error | RuntimeException exception) {
              wrapped.put("error", wrapError(exception));
            }
            reply.reply(wrapped);
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
