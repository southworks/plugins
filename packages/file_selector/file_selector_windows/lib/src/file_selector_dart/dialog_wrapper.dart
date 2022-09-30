// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:win32/win32.dart';

import 'dialog_mode.dart';
import 'ifile_dialog_controller_factory.dart';

/// Wraps an IFileDialog, managing object lifetime as a scoped object and
/// providing a simplified API for interacting with it as needed for the plugin.
class DialogWrapper {
  // ignore: public_member_api_docs
  DialogWrapper(IFileDialogControllerFactory fileDialogControllerFactory,
      DialogMode dialogMode)
      : _factoryDialog = fileDialogControllerFactory,
        _dialogMode = dialogMode;

  final int _lastResult = S_OK;
  // ignore: unused_field
  final IFileDialogControllerFactory _factoryDialog;
  // ignore: unused_field
  final DialogMode _dialogMode;

  /// Attempts to set the default folder for the dialog to |path|,
  /// if it exists.
  void setFolder(String path) {}

  /// Sets the file name that is initially shown in the dialog.
  void setFileName(String name) {}

  /// Sets the label of the confirmation button.
  void setOkButtonLabel(String label) {}

  /// Adds the given options to the dialog's current option set.
  void addOptions(FILEOPENDIALOGOPTIONS newOptions) {}

  /// Sets the filters for allowed file types to select.
  /// filters -> std::optional<EncodableList>
  void setFileTypeFilters(List<XTypeGroup> filters) {}

  /// Displays the dialog, and returns the selected files, or nullopt on error.
  /// std::optional<EncodableList>
  void show(HWND parentWindow) {}

  /// Returns the result of the last Win32 API call related to this object.
  int lastResult() {
    return _lastResult;
  }
}
