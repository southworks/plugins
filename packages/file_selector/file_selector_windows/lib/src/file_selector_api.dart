// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'file_selector_dart/dialog_mode.dart';
import 'file_selector_dart/dialog_wrapper.dart';
import 'file_selector_dart/file_dialog_controller_factory.dart';
import 'file_selector_dart/ifile_dialog_controller_factory.dart';
import 'file_selector_dart/ifile_dialog_factory.dart';
import 'file_selector_dart/selection_options.dart';

/// File dialog handling for Open and Save operations.
class FileSelectorApi {
  /// Creates a new instance of [FileSelectorApi].
  /// Allows Dependency Injection of a [IFileDialogControllerFactory] and [IFileDialogFactory] to handle dialog creation.
  FileSelectorApi(this._fileDialogControllerFactory, this._fileDialogFactory);

  final IFileDialogControllerFactory _fileDialogControllerFactory;

  final IFileDialogFactory _fileDialogFactory;

  /// Displays a dialog window to open one or more files.
  List<String?> showOpenDialog(
    SelectionOptions options,
    String? initialDirectory,
    String? confirmButtonText,
  ) =>
      _showDialog(0, DialogMode.Save, options, initialDirectory, null,
          confirmButtonText);

  /// Displays a dialog used to save a file.
  List<String?> showSaveDialog(
    SelectionOptions options,
    String? initialDirectory,
    String? suggestedName,
    String? confirmButtonText,
  ) =>
      _showDialog(0, DialogMode.Save, options, initialDirectory, suggestedName,
          confirmButtonText);

  List<String?> _showDialog(
      int parentWindow,
      DialogMode mode,
      SelectionOptions options,
      String? initialDirectory,
      String? suggestedName,
      String? confirmLabel) {
    final DialogWrapper dialogWrapper =
        DialogWrapper(_fileDialogControllerFactory, _fileDialogFactory, mode);
    if (!SUCCEEDED(dialogWrapper.lastResult)) {
      throw WindowsException(E_FAIL);
    }
    int dialogOptions = 0;
    if (options.selectFolders) {
      dialogOptions |= FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS;
    }
    if (options.allowMultiple) {
      dialogOptions |= FILEOPENDIALOGOPTIONS.FOS_ALLOWMULTISELECT;
    }
    if (dialogOptions != 0) {
      dialogWrapper.addOptions(dialogOptions);
    }

    if (initialDirectory != null) {
      dialogWrapper.setFolder(initialDirectory);
    }
    if (suggestedName != null) {
      dialogWrapper.setFileName(suggestedName);
    }
    if (confirmLabel != null) {
      dialogWrapper.setOkButtonLabel(confirmLabel);
    }

    if (options.allowedTypes.isNotEmpty) {
      dialogWrapper.setFileTypeFilters(options.allowedTypes);
    }

    final List<String?>? files = dialogWrapper.show(parentWindow);
    if (files != null) {
      return files;
    }
    throw WindowsException(E_FAIL);
  }
}
