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
  /// We need the file to exist. This value is default to `false`.
  DartFileSelectorAPI(
      [FileOpenDialogAPI? fileOpenDialogAPI, ShellItemAPI? shellItemAPI])
      : super() {
    fileMustExist = true;
    _fileOpenDialogAPI = fileOpenDialogAPI ?? FileOpenDialogAPI();
    _shellItemAPI = shellItemAPI ?? ShellItemAPI();
  }

  late FileOpenDialogAPI _fileOpenDialogAPI;
  late ShellItemAPI _shellItemAPI;

  /// Returns directory path from user selection.
  String? getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    return _getDirectory(
        initialDirectory: initialDirectory,
        confirmButtonText: confirmButtonText);
  }

  /// Returns a list of file paths.
  List<String> getFile(SelectionOptions selectionOptions,
      String? initialDirectory, String? confirmButtonText) {
    int hResult = initializeComLibrary();
    final FileOpenDialog fileDialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> options = arena<Uint32>();

      /// aca hay que mandar la configuracion de multi file.
      hResult = getOptions(options, hResult, fileDialog);
      hResult =
          setDialogOptions(options, hResult, selectionOptions, fileDialog);
    });

    hResult = setInitialDirectory(initialDirectory, fileDialog);
    hResult = addFileFilters(hResult, fileDialog, selectionOptions);
    hResult = addConfirmButtonLabel(fileDialog, confirmButtonText);
    hResult = _fileOpenDialogAPI.show(hWndOwner, fileDialog);

    return returnSelectedElement(hResult, selectionOptions, fileDialog);
  }

  /// Returns dialog options.
  @visibleForTesting
  int getOptions(Pointer<Uint32> pfos, int hResult, IFileOpenDialog dialog) {
    hResult = _fileOpenDialogAPI.getOptions(pfos, dialog);
    _validateResult(hResult);

    return hResult;
  }

  int _getDialogOptions(int options, SelectionOptions selectionOptions) {
    if (hidePinnedPlaces) {
      options |= FILEOPENDIALOGOPTIONS.FOS_HIDEPINNEDPLACES;
    }

    if (fileMustExist) {
      options |= FILEOPENDIALOGOPTIONS.FOS_PATHMUSTEXIST;
    }

    if (forceFileSystemItems) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM;
    }

    if (isDirectoryFixed) {
      options |= FILEOPENDIALOGOPTIONS.FOS_NOCHANGEDIR;
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
  int setDialogOptions(Pointer<Uint32> pfos, int hResult,
      SelectionOptions selectionOptions, IFileOpenDialog dialog) {
    final int options = _getDialogOptions(pfos.value, selectionOptions);

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
      final Pointer<GUID> guid = GUIDFromString(IID_IShellItem);
      final Pointer<Pointer<COMObject>> dirPath = arena<Pointer<COMObject>>();
      result = SHCreateItemFromParsingName(
          TEXT(initialDirectory), nullptr, guid, dirPath);

      if (FAILED(result)) {
        throw WindowsException(result);
      }

      result = _fileOpenDialogAPI.setFolder(dirPath, dialog);

      if (FAILED(result)) {
        throw WindowsException(result);
      }
    });

    return result;
  }

  String? _getDirectory({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    final SelectionOptions selectionOptions = SelectionOptions(
        allowMultiple: false, selectFolders: true, allowedTypes: <TypeGroup>[]);
    int hResult = initializeComLibrary();
    final FileOpenDialog dialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> options = arena<Uint32>();
      hResult = getOptions(options, hResult, dialog);
      hResult = setDialogOptions(options, hResult, selectionOptions, dialog);
    });

    hResult = setInitialDirectory(initialDirectory, dialog);
    hResult = addConfirmButtonLabel(dialog, confirmButtonText);
    hResult = _fileOpenDialogAPI.show(hWndOwner, dialog);

    final List<String> selectedPaths =
        returnSelectedElement(hResult, selectionOptions, dialog);
    return selectedPaths.isEmpty ? null : selectedPaths.first;
  }

  /// Initialices the com library
  @visibleForTesting
  int initializeComLibrary() {
    final int hResult = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    _validateResult(hResult);
    return hResult;
  }

  /// Returns a directory path from user interaction.
  @visibleForTesting
  List<String> returnSelectedElement(
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

  void _validateResult(int hResult) {
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
  }

  int _getSelectedPathsFromUserInput(SelectionOptions selectionOptions,
      int hResult, FileOpenDialog dialog, List<String> selectedElements) {
    using((Arena arena) {
      final Pointer<Pointer<COMObject>> ppsi = arena<Pointer<COMObject>>();

      if (selectionOptions.allowMultiple) {
        hResult = _fileOpenDialogAPI.getResults(ppsi, dialog);
        final IShellItemArray iShellItemArray =
            _shellItemAPI.createShellItemArray(ppsi);
        final Pointer<Uint32> numberOfSelectedElements = arena<Uint32>();
        _shellItemAPI.getCount(numberOfSelectedElements, iShellItemArray);

        for (int i = 0; i < numberOfSelectedElements.value; i++) {
          final Pointer<Pointer<COMObject>> item = arena<Pointer<COMObject>>();

          hResult = _shellItemAPI.getItemAt(i, item, iShellItemArray);
          _validateResult(hResult);

          hResult =
              _addSelectedPathFromPpsi(item, arena, hResult, selectedElements);

          _shellItemAPI.release(iShellItemArray);
        }
      } else {
        hResult = _fileOpenDialogAPI.getResult(ppsi, dialog);
        _validateResult(hResult);
        hResult =
            _addSelectedPathFromPpsi(ppsi, arena, hResult, selectedElements);
      }
    });

    _validateResult(hResult);

    return hResult;
  }

  int _addSelectedPathFromPpsi(Pointer<Pointer<COMObject>> ppsi, Arena arena,
      int hResult, List<String> selectedElements) {
    final IShellItem item = _shellItemAPI.createShellItem(ppsi);
    final Pointer<IntPtr> pathPtrPtr = arena<IntPtr>();

    hResult = _shellItemAPI.getDisplayName(pathPtrPtr, item);
    _validateResult(hResult);

    selectedElements.add(_shellItemAPI.getUserSelectedPath(pathPtrPtr));
    hResult = _shellItemAPI.releaseItem(item);
    _validateResult(hResult);

    return hResult;
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
      hResult = _fileOpenDialogAPI.setFileTypes(
          filterSpecification, hResult, fileDialog);

      _validateResult(hResult);
    }

    return hResult;
  }
}
