import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:win32/win32.dart';

import 'dart_file_dialog.dart';
import 'dart_file_open_dialog_api.dart';
import 'dart_shell_item_api.dart';

/// Dart native implementation of FileSelectorAPI
class DartFileSelectorAPI extends FileDialog {
  /// We need the file to exist. This value defaults to `false`.
  DartFileSelectorAPI(
      [FileOpenDialogAPI? fileOpenDialogAPI, ShellItemAPI? shellItemAPI])
      : super() {
    _fileOpenDialogAPI = fileOpenDialogAPI ?? FileOpenDialogAPI();
    _shellItemAPI = shellItemAPI ?? ShellItemAPI();
  }

  late FileOpenDialogAPI _fileOpenDialogAPI;
  late ShellItemAPI _shellItemAPI;

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
    final FileOpenDialog fileDialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> ptrOptions = arena<Uint32>();

      hResult = getOptions(ptrOptions, hResult, fileDialog);
      hResult =
          setDialogOptions(ptrOptions, hResult, selectionOptions, fileDialog);
    });

    hResult = setInitialDirectory(initialDirectory, fileDialog);
    hResult = addFileFilters(hResult, fileDialog, selectionOptions);
    hResult = addConfirmButtonLabel(fileDialog, confirmButtonText);
    hResult = _fileOpenDialogAPI.show(hWndOwner, fileDialog);

    return returnSelectedElements(hResult, selectionOptions, fileDialog);
  }

  /// Returns dialog options.
  @visibleForTesting
  int getOptions(
      Pointer<Uint32> ptrOptions, int hResult, IFileOpenDialog dialog) {
    hResult = _fileOpenDialogAPI.getOptions(ptrOptions, dialog);
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
  int setDialogOptions(Pointer<Uint32> ptrOptions, int hResult,
      SelectionOptions selectionOptions, IFileOpenDialog dialog) {
    final int options = getDialogOptions(ptrOptions.value, selectionOptions);

    hResult = _fileOpenDialogAPI.setOptions(options, dialog);

    _validateResult(hResult);

    return hResult;
  }

  /// Sets the initial directory to open the dialog
  @visibleForTesting
  int setInitialDirectory(String? initialDirectory, IFileOpenDialog dialog) {
    int result = 0;

    if (initialDirectory == null || initialDirectory.isEmpty) {
      return result;
    }

    using((Arena arena) {
      final Pointer<GUID> ptrGuid = GUIDFromString(IID_IShellItem);
      final Pointer<Pointer<COMObject>> ptrPath = arena<Pointer<COMObject>>();
      result = _fileOpenDialogAPI.createItemFromParsingName(
          initialDirectory, ptrGuid, ptrPath);

      _validateResult(result);

      result = _fileOpenDialogAPI.setFolder(ptrPath, dialog);

      _validateResult(result);
    });

    return result;
  }

  /// Initialices the com library
  @visibleForTesting
  int initializeComLibrary() {
    final int hResult = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    _validateResult(hResult);
    return hResult;
  }

  /// Returns a list directory paths from user interaction.
  @visibleForTesting
  List<String> returnSelectedElements(
      int hResult, SelectionOptions selectionOptions, FileOpenDialog dialog) {
    final List<String> selectedElements = <String>[];
    if (FAILED(hResult)) {
      if (hResult != HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        throw WindowsException(hResult);
      }
    } else {
      hResult = _getSelectedPathsFromUserInput(
          selectionOptions, hResult, dialog, selectedElements);
    }

    hResult = _fileOpenDialogAPI.release(dialog);
    _validateResult(hResult);

    CoUninitialize();
    return selectedElements;
  }

  /// Add confirmation button text.
  @visibleForTesting
  int addConfirmButtonLabel(FileOpenDialog dialog, String? confirmButtonText) {
    return _fileOpenDialogAPI.setOkButtonLabel(confirmButtonText, dialog);
  }

  /// Adds file type filters.
  @visibleForTesting
  int addFileFilters(int hResult, FileOpenDialog fileDialog,
      SelectionOptions selectionOptions) {
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

    if (filterSpecification.isNotEmpty) {
      hResult =
          _fileOpenDialogAPI.setFileTypes(filterSpecification, fileDialog);
      _validateResult(hResult);
    }

    return hResult;
  }

  /// Set the suggested file name of the given dialog.
  @visibleForTesting
  int setSuggestedFileName(
      String? suggestedFileName, int hResult, FileOpenDialog fileDialog) {
    if (suggestedFileName != null && suggestedFileName.isNotEmpty) {
      hResult = _fileOpenDialogAPI.setFileName(suggestedFileName, fileDialog);
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
    final FileOpenDialog dialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> ptrOptions = arena<Uint32>();
      hResult = getOptions(ptrOptions, hResult, dialog);
      hResult = setDialogOptions(ptrOptions, hResult, selectionOptions, dialog);
    });

    hResult = setInitialDirectory(initialDirectory, dialog);
    hResult = addFileFilters(hResult, dialog, selectionOptions);
    hResult = addConfirmButtonLabel(dialog, confirmButtonText);
    hResult = setSuggestedFileName(suggestedFileName, hResult, dialog);
    hResult = _fileOpenDialogAPI.show(hWndOwner, dialog);

    final List<String> selectedPaths =
        returnSelectedElements(hResult, selectionOptions, dialog);
    return selectedPaths.isEmpty ? null : selectedPaths.first;
  }

  void _validateResult(int hResult) {
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
  }

  int _getSelectedPathsFromUserInput(SelectionOptions selectionOptions,
      int hResult, FileOpenDialog dialog, List<String> selectedElements) {
    using((Arena arena) {
      final Pointer<Pointer<COMObject>> ptrShellItemArray =
          arena<Pointer<COMObject>>();

      if (selectionOptions.allowMultiple) {
        hResult = _fileOpenDialogAPI.getResults(ptrShellItemArray, dialog);
        _validateResult(hResult);
        final IShellItemArray iShellItemArray =
            _shellItemAPI.createShellItemArray(ptrShellItemArray);
        final Pointer<Uint32> ptrNumberOfSelectedElements = arena<Uint32>();
        _shellItemAPI.getCount(ptrNumberOfSelectedElements, iShellItemArray);

        for (int index = 0;
            index < ptrNumberOfSelectedElements.value;
            index++) {
          final Pointer<Pointer<COMObject>> ptrShellItem =
              arena<Pointer<COMObject>>();

          hResult =
              _shellItemAPI.getItemAt(index, ptrShellItem, iShellItemArray);
          _validateResult(hResult);

          hResult = _addSelectedPathFromPpsi(
              ptrShellItem, arena, hResult, selectedElements);

          _shellItemAPI.release(iShellItemArray);
        }
      } else {
        hResult = _fileOpenDialogAPI.getResult(ptrShellItemArray, dialog);
        _validateResult(hResult);
        hResult = _addSelectedPathFromPpsi(
            ptrShellItemArray, arena, hResult, selectedElements);
      }
    });

    _validateResult(hResult);

    return hResult;
  }

  int _addSelectedPathFromPpsi(Pointer<Pointer<COMObject>> ptrShellItem,
      Arena arena, int hResult, List<String> selectedElements) {
    final IShellItem shellItem = _shellItemAPI.createShellItem(ptrShellItem);
    final Pointer<IntPtr> ptrPath = arena<IntPtr>();

    hResult = _shellItemAPI.getDisplayName(ptrPath, shellItem);
    _validateResult(hResult);

    selectedElements.add(_shellItemAPI.getUserSelectedPath(ptrPath));
    hResult = _shellItemAPI.releaseItem(shellItem);
    _validateResult(hResult);

    return hResult;
  }
}
