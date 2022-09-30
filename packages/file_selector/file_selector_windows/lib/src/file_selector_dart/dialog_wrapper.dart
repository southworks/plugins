// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_platform_interface/file_selector_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:win32/win32.dart';

import 'dialog_mode.dart';
import 'file_dialog_controller.dart';
import 'ifile_dialog_controller_factory.dart';
import 'ifile_dialog_factory.dart';

/// Wraps an IFileDialog, managing object lifetime as a scoped object and
/// providing a simplified API for interacting with it as needed for the plugin.
class DialogWrapper {
  /// Creates a DialogWrapper using a [IFileDialogControllerFactory] and a [DialogMode].
  /// It also resposible of creating a [IFileDialog].
  DialogWrapper(IFileDialogControllerFactory fileDialogControllerFactory,
      IFileDialogFactory fileDialogFactory, DialogMode dialogMode)
      : _fileDialogControllerFactory = fileDialogControllerFactory,
        _fileDialogFactory = fileDialogFactory,
        _dialogMode = dialogMode,
        _isOpenDialog = dialogMode == DialogMode.Open {
    try {
      final IFileDialog dialog = fileDialogFactory.createInstace(_dialogMode);
      _dialogController = _fileDialogControllerFactory.createController(dialog);
    } catch (ex) {
      if (ex is WindowsException) {
        _lastResult = ex.hr;
      }
    }
  }

  /// Creates a DialogWrapper for testing purposes.
  @visibleForTesting
  DialogWrapper.test(
      FileDialogController dialogController,
      this._fileDialogControllerFactory,
      this._fileDialogFactory,
      this._dialogMode,
      this._isOpenDialog) {
    _dialogController = dialogController;
  }

  int _lastResult = S_OK;
  // ignore: unused_field
  final IFileDialogControllerFactory _fileDialogControllerFactory;
  // ignore: unused_field
  final IFileDialogFactory _fileDialogFactory;
  // ignore: unused_field
  final DialogMode _dialogMode;
  // ignore: unused_field
  final bool _isOpenDialog;
  // ignore: unused_field
  bool _openingDirectory = false;
  // ignore: unused_field
  late FileDialogController _dialogController;

  /// Returns the result of the last Win32 API call related to this object.
  int get lastResult => _lastResult;

  /// Attempts to set the default folder for the dialog to |path|,
  /// if it exists.
  void setFolder(String path) {}

  /// Sets the file name that is initially shown in the dialog.
  void setFileName(String name) {
    _dialogController.setFileName(name);
  }

  /// Sets the label of the confirmation button.
  void setOkButtonLabel(String label) {
    _dialogController.setOkButtonLabel(label);
  }

  /// Adds the given options to the dialog's current [options](https://pub.dev/documentation/win32/latest/winrt/FILEOPENDIALOGOPTIONS-class.html).
  /// Both are bitfields.
  void addOptions(int newOptions) {
    using((Arena arena) {
      final Pointer<Uint32> currentOptions = arena<Uint32>();
      _lastResult = _dialogController.getOptions(currentOptions);
      if (!SUCCEEDED(_lastResult)) {
        return;
      }

      currentOptions.value |= newOptions;

      if (currentOptions.value & FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS ==
          currentOptions.value) {
        _openingDirectory = true;
      }

      _lastResult = _dialogController.setOptions(currentOptions.value);
    });
  }

  /// Sets the filters for allowed file types to select.
  /// filters -> std::optional<EncodableList>
  void setFileTypeFilters(List<XTypeGroup> filters) {}

  /// Displays the dialog, and returns the selected files, or nullopt on error.
  /// std::optional<EncodableList>
  void show(HWND parentWindow) {}

  /// Returns the path for [shellItem] as a UTF-8 string, or an empty string on
  /// failure.
  String getPathForShellItem(IShellItem shellItem) {
    // TODO(eugeniorossetto): Review this implementation.
    return using((Arena arena) {
      final Pointer<Pointer<Utf16>> ptrPath = arena<Pointer<Utf16>>();

      if (!SUCCEEDED(
          shellItem.getDisplayName(SIGDN.SIGDN_FILESYSPATH, ptrPath.cast()))) {
        return '';
      }

      final Pointer<Utf16> path = Pointer<Utf16>.fromAddress(ptrPath.address);
      return path.toDartString();
    });
  }
}
