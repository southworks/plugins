// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'file_selector_dart/dialog_mode.dart';
import 'file_selector_dart/selection_options.dart';

/// File dialog handling for Open and Save operations.
class FileSelectorApi {

  /// Displays a dialog window to open one or more files.
  List<String?> showOpenDialog(
    SelectionOptions options,
    String? initialDirectory,
    String? confirmButtonText,
  ) => _showDialog(0, DialogMode.Save, options, initialDirectory, null, confirmButtonText);

  /// Displays a dialog used to save a file.
  List<String?> showSaveDialog(
    SelectionOptions options,
    String? initialDirectory,
    String? suggestedName,
    String? confirmButtonText,
  ) => _showDialog(0, DialogMode.Save, options, initialDirectory, suggestedName, confirmButtonText);

  List<String?> _showDialog(int parentWindow,
    DialogMode mode, SelectionOptions options,
    String? initialDirectory, String? suggestedName,
    String? confirmLabel)
    {

    }
}
