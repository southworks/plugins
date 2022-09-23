// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:win32/win32.dart';

import 'file_dialog.dart';
import 'file_open_dialog_wrapper.dart';
import 'shell_item_wrapper.dart';

/// Implementation of FileDialog. It provides primitives to interact with the file system including:
/// * Open a file.
/// * Open multiple files.
/// * Select a directory.
/// * Return a file path to save a file.
class FileSelector extends FileDialog {
  /// Initializes a FileSelector instance. It receives a FileOpenDialogWrapper and a ShellItemWrapper allowing dependency injection, both of which can be null.
  FileSelector(FileOpenDialogWrapper? fileOpenDialogWrapper,
      ShellItemWrapper? shellItemWrapper)
      : super() {
    _fileOpenDialogWrapper = fileOpenDialogWrapper ?? FileOpenDialogWrapper();
    _shellItemWrapper = shellItemWrapper ?? ShellItemWrapper();
  }

  /// Initializes a FileSelector instance. It receives a FileOpenDialogWrapper and a ShellItemWrapper allowing dependency injection, both of which can be null.
  FileSelector.withoutParameters() : this(null, null);

  late FileOpenDialogWrapper _fileOpenDialogWrapper;
  late ShellItemWrapper _shellItemWrapper;

  /// Returns a directory path from user selection.
  String? getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    fileMustExist = true;
    final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false, selectFolders: true, allowedTypes: <TypeGroup>[]);
    return _getDirectory(
        initialDirectory: initialDirectory,
        confirmButtonText: confirmButtonText,
        selectionOptions: selectionOptions);
  }

  /// Returns a full path, including file name and it's extension, from user selection.
  String? getSavePath({
    String? initialDirectory,
    String? confirmButtonText,
    String? suggestedFileName,
    SelectionOptions? selectionOptions,
  }) {
    fileMustExist = false;
    final SelectionOptions defaultSelectionOptions = SelectionOptions(
        allowMultiple: false, selectFolders: true, allowedTypes: <TypeGroup>[]);
    return _getDirectory(
        initialDirectory: initialDirectory,
        confirmButtonText: confirmButtonText,
        suggestedFileName: suggestedFileName,
        selectionOptions: selectionOptions ?? defaultSelectionOptions);
  }

  /// Returns a list of file paths.
  List<String> getFiles(
      {String? initialDirectory,
      String? confirmButtonText,
      required SelectionOptions selectionOptions}) {
    fileMustExist = false;
    int hResult = initializeComLibrary();
    final IFileOpenDialog fileDialog = _fileOpenDialogWrapper.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> ptrOptions = arena<Uint32>();

      hResult = getOptions(ptrOptions, fileDialog);
      hResult = setDialogOptions(ptrOptions, selectionOptions, fileDialog);
    });

    hResult = setInitialDirectory(initialDirectory, fileDialog);
    hResult = addFileFilters(selectionOptions, fileDialog);
    hResult = addConfirmButtonLabel(confirmButtonText, fileDialog);
    hResult = _fileOpenDialogWrapper.show(hWndOwner, fileDialog);

    return returnSelectedElements(hResult, selectionOptions, fileDialog);
  }

  /// Returns dialog options.
  @visibleForTesting
  int getOptions(Pointer<Uint32> ptrOptions, IFileOpenDialog dialog) {
    final int hResult = _fileOpenDialogWrapper.getOptions(ptrOptions, dialog);
    _validateResult(hResult);

    return hResult;
  }

  /// Returns the dialog option based on conditions.
  @visibleForTesting
  int getDialogOptions(int options, SelectionOptions selectionOptions) {
    if (!fileMustExist) {
      options &= ~FILEOPENDIALOGOPTIONS.FOS_PATHMUSTEXIST;
      options &= ~FILEOPENDIALOGOPTIONS.FOS_FILEMUSTEXIST;
    }

    if (selectionOptions.selectFolders) {
      options |= FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS;
    }

    if (selectionOptions.allowMultiple) {
      options |= FILEOPENDIALOGOPTIONS.FOS_ALLOWMULTISELECT;
    }

    return options;
  }

  /// Sets and checks options for the dialog.
  @visibleForTesting
  int setDialogOptions(Pointer<Uint32> ptrOptions,
      SelectionOptions selectionOptions, IFileOpenDialog dialog) {
    final int options = getDialogOptions(ptrOptions.value, selectionOptions);

    final int hResult = _fileOpenDialogWrapper.setOptions(options, dialog);

    _validateResult(hResult);

    return hResult;
  }

  /// Sets the initial directory to open the dialog
  @visibleForTesting
  int setInitialDirectory(String? initialDirectory, IFileOpenDialog dialog) {
    int hResult = 0;

    if (initialDirectory == null || initialDirectory.isEmpty) {
      return hResult;
    }

    using((Arena arena) {
      final Pointer<GUID> ptrGuid = GUIDFromString(IID_IShellItem);
      final Pointer<Pointer<COMObject>> ptrPath = arena<Pointer<COMObject>>();
      hResult = _fileOpenDialogWrapper.createItemFromParsingName(
          initialDirectory, ptrGuid, ptrPath);

      _validateResult(hResult);

      hResult = _fileOpenDialogWrapper.setFolder(ptrPath, dialog);

      _validateResult(hResult);
    });

    return hResult;
  }

  /// Initialices the com library
  @visibleForTesting
  int initializeComLibrary() {
    final int hResult = _fileOpenDialogWrapper.coInitializeEx();
    _validateResult(hResult);
    return hResult;
  }

  /// Returns a list directory paths from user interaction.
  @visibleForTesting
  List<String> returnSelectedElements(
      int hResult, SelectionOptions selectionOptions, IFileOpenDialog dialog) {
    final List<String> selectedElements = <String>[];

    if (FAILED(hResult)) {
      if (hResult != HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        throw WindowsException(hResult);
      }
    } else {
      hResult = _getSelectedPathsFromUserInput(
          selectionOptions, selectedElements, dialog);
    }

    hResult = _fileOpenDialogWrapper.release(dialog);
    _validateResult(hResult);

    _fileOpenDialogWrapper.coUninitialize();
    return selectedElements;
  }

  /// Add confirmation button text.
  @visibleForTesting
  int addConfirmButtonLabel(
    String? confirmButtonText,
    IFileOpenDialog dialog,
  ) {
    final int hResult =
        _fileOpenDialogWrapper.setOkButtonLabel(confirmButtonText, dialog);
    _validateResult(hResult);
    return hResult;
  }

  /// Adds file type filters.
  @visibleForTesting
  int addFileFilters(
      SelectionOptions selectionOptions, IFileOpenDialog fileDialog) {
    clearFilterSpecification();
    for (final TypeGroup? option in selectionOptions.allowedTypes) {
      if (option == null ||
          option.extensions == null ||
          option.extensions.isEmpty) {
        continue;
      }

      final String label = option.label;
      String extensionsForLabel = '';
      for (final String? extensionFile in option.extensions) {
        if (extensionFile != null) {
          extensionsForLabel += '*.$extensionFile;';
        }
      }
      filterSpecification[label] = extensionsForLabel;
    }

    int hResult = 0;
    if (filterSpecification.isNotEmpty) {
      hResult =
          _fileOpenDialogWrapper.setFileTypes(filterSpecification, fileDialog);
      _validateResult(hResult);
    }

    return hResult;
  }

  /// Set the suggested file name of the given dialog.
  @visibleForTesting
  int setSuggestedFileName(
      String? suggestedFileName, IFileOpenDialog fileDialog) {
    int hResult = 0;
    if (suggestedFileName != null && suggestedFileName.isNotEmpty) {
      hResult =
          _fileOpenDialogWrapper.setFileName(suggestedFileName, fileDialog);
      _validateResult(hResult);
    }

    return hResult;
  }

  String? _getDirectory({
    String? initialDirectory,
    String? confirmButtonText,
    String? suggestedFileName,
    required SelectionOptions selectionOptions,
  }) {
    int hResult = initializeComLibrary();
    final IFileOpenDialog dialog = _fileOpenDialogWrapper.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> ptrOptions = arena<Uint32>();
      hResult = getOptions(ptrOptions, dialog);
      hResult = setDialogOptions(ptrOptions, selectionOptions, dialog);
    });

    hResult = setInitialDirectory(initialDirectory, dialog);
    hResult = addFileFilters(selectionOptions, dialog);
    hResult = addConfirmButtonLabel(confirmButtonText, dialog);
    hResult = setSuggestedFileName(suggestedFileName, dialog);
    hResult = _fileOpenDialogWrapper.show(hWndOwner, dialog);

    final List<String> selectedPaths =
        returnSelectedElements(hResult, selectionOptions, dialog);
    return selectedPaths.isEmpty ? null : selectedPaths.first;
  }

  void _validateResult(int hResult) {
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
  }

  int _getSelectedPathsFromUserInput(
    SelectionOptions selectionOptions,
    List<String> selectedElements,
    IFileOpenDialog dialog,
  ) {
    int hResult = 0;
    using((Arena arena) {
      final Pointer<Pointer<COMObject>> ptrShellItemArray =
          arena<Pointer<COMObject>>();

      if (selectionOptions.allowMultiple) {
        hResult = _fileOpenDialogWrapper.getResults(ptrShellItemArray, dialog);
        _validateResult(hResult);
        final IShellItemArray iShellItemArray =
            _shellItemWrapper.createShellItemArray(ptrShellItemArray);
        final Pointer<Uint32> ptrNumberOfSelectedElements = arena<Uint32>();
        _shellItemWrapper.getCount(
            ptrNumberOfSelectedElements, iShellItemArray);

        for (int index = 0;
            index < ptrNumberOfSelectedElements.value;
            index++) {
          final Pointer<Pointer<COMObject>> ptrShellItem =
              arena<Pointer<COMObject>>();

          hResult =
              _shellItemWrapper.getItemAt(index, ptrShellItem, iShellItemArray);
          _validateResult(hResult);

          hResult =
              _addSelectedPathFromPpsi(ptrShellItem, arena, selectedElements);

          _shellItemWrapper.release(iShellItemArray);
        }
      } else {
        hResult = _fileOpenDialogWrapper.getResult(ptrShellItemArray, dialog);
        _validateResult(hResult);
        hResult = _addSelectedPathFromPpsi(
            ptrShellItemArray, arena, selectedElements);
      }
    });

    _validateResult(hResult);

    return hResult;
  }

  int _addSelectedPathFromPpsi(Pointer<Pointer<COMObject>> ptrShellItem,
      Arena arena, List<String> selectedElements) {
    final IShellItem shellItem =
        _shellItemWrapper.createShellItem(ptrShellItem);
    final Pointer<IntPtr> ptrPath = arena<IntPtr>();

    int hResult = _shellItemWrapper.getDisplayName(ptrPath, shellItem);
    _validateResult(hResult);

    selectedElements.add(_shellItemWrapper.getUserSelectedPath(ptrPath));
    hResult = _shellItemWrapper.releaseItem(shellItem);
    _validateResult(hResult);

    return hResult;
  }
}
