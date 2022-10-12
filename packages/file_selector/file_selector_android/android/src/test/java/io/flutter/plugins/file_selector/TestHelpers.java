// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

package io.flutter.plugins.file_selector;

import static io.flutter.plugins.file_selector.FileSelectorDelegate._acceptedTypeGroups;
import static io.flutter.plugins.file_selector.FileSelectorDelegate._confirmButtonText;
import static io.flutter.plugins.file_selector.FileSelectorDelegate._initialDirectory;
import static io.flutter.plugins.file_selector.FileSelectorDelegate._multiple;

import androidx.annotation.Nullable;
import io.flutter.plugin.common.MethodCall;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Map;

public class TestHelpers {
  public static MethodCall buildMethodCall(
      String method,
      @Nullable String initialDirectory,
      @Nullable String confirmButtonText,
      @Nullable Boolean multiple,
      @Nullable ArrayList acceptedTypeGroups) {
    final Map<String, Object> arguments = new HashMap<>();
    if (initialDirectory != null) {
      arguments.put(_initialDirectory, initialDirectory);
    }
    if (confirmButtonText != null) {
      arguments.put(_confirmButtonText, confirmButtonText);
    }
    if (acceptedTypeGroups != null) {
      arguments.put(_acceptedTypeGroups, acceptedTypeGroups);
    }
    arguments.put(_multiple, multiple != null ? multiple : false);

    return new MethodCall(method, arguments);
  }

  public static MethodCall buildMethodCall(String method) {
    return new MethodCall(method, null);
  }
}
