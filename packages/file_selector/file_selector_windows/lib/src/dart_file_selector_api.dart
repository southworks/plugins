import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:win32/win32.dart';

import 'dart_file_dialog.dart';
import 'dart_file_open_dialog_api.dart';

/// Dart native implementation of FileSelectorAPI
class DartFileSelectorAPI extends FileDialog {
  /// We need the file to exist. This value is default to `false`.
  DartFileSelectorAPI([FileOpenDialogAPI? fileOpenDialogAPI]) : super() {
    fileMustExist = true;
    _fileOpenDialogAPI = fileOpenDialogAPI ?? FileOpenDialogAPI();
  }

  late FileOpenDialogAPI _fileOpenDialogAPI;

  /// Returns directory path from user selection
  String? getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    return _getDirectory(
        initialDirectory: initialDirectory,
        confirmButtonText: confirmButtonText);
  }

  /// Returns a file.
  String? getFile(SelectionOptions selectionOptions, String? initialDirectory,
      String? confirmButtonText) {
    int hResult = initializeComLibrary();
    final FileOpenDialog fileDialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> options = arena<Uint32>();
      hResult = getOptions(options, hResult, fileDialog);
      hResult = setFileOptions(options, hResult, fileDialog);
    });

    hResult = setInitialDirectory(initialDirectory, fileDialog);
    hResult = addFileFilters(hResult, fileDialog, selectionOptions);
    hResult = addConfirmButtonLabel(fileDialog, confirmButtonText);
    hResult = _fileOpenDialogAPI.show(hWndOwner, fileDialog);
    return returnSelectedElement(hResult, fileDialog);
  }

  /// Returns dialog options.
  @visibleForTesting
  int getOptions(Pointer<Uint32> pfos, int hResult, IFileOpenDialog dialog) {
    hResult = _fileOpenDialogAPI.getOptions(pfos, dialog);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    return hResult;
  }

  /// Sets and checks options for the dialog.
  @visibleForTesting
  int setDirectoryOptions(
      Pointer<Uint32> pfos, int hResult, IFileOpenDialog dialog) {
    int options = pfos.value;

    options |= FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS;

    options = _getFileOptions(options);

    hResult = _fileOpenDialogAPI.setOptions(options, dialog);

    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    return hResult;
  }

  int _getFileOptions(int options) {
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
    return options;
  }

  /// Sets and checks options for the dialog.
  @visibleForTesting
  int setFileOptions(
      Pointer<Uint32> pfos, int hResult, IFileOpenDialog dialog) {
    final int options = _getFileOptions(pfos.value);

    hResult = _fileOpenDialogAPI.setOptions(options, dialog);

    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

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
    int hResult = initializeComLibrary();
    final FileOpenDialog dialog = FileOpenDialog.createInstance();
    using((Arena arena) {
      final Pointer<Uint32> options = arena<Uint32>();
      hResult = getOptions(options, hResult, dialog);
      hResult = setDirectoryOptions(options, hResult, dialog);
    });

    hResult = setInitialDirectory(initialDirectory, dialog);
    hResult = addConfirmButtonLabel(dialog, confirmButtonText);
    hResult = _fileOpenDialogAPI.show(hWndOwner, dialog);
    return returnSelectedElement(hResult, dialog);
  }

  /// Initialices the com library
  @visibleForTesting
  int initializeComLibrary() {
    final int hResult = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    return hResult;
  }

  /// Returns a directory path from user interaction.
  @visibleForTesting
  String? returnSelectedElement(int hResult, FileOpenDialog dialog) {
    bool cancelledByUser = false;
    late String userSelectedPath;
    if (FAILED(hResult)) {
      if (hResult == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        cancelledByUser = true;
      } else {
        throw WindowsException(hResult);
      }
    } else {
      using((Arena arena) {
        final Pointer<Pointer<COMObject>> ppsi = arena<Pointer<COMObject>>();
        hResult = _fileOpenDialogAPI.getResult(ppsi, dialog);
        if (FAILED(hResult)) {
          throw WindowsException(hResult);
        }

        final IShellItem item = IShellItem(ppsi.cast());
        final Pointer<IntPtr> pathPtrPtr = arena<IntPtr>();

        hResult = _fileOpenDialogAPI.getDisplayName(item, pathPtrPtr);
        if (FAILED(hResult)) {
          throw WindowsException(hResult);
        }

        userSelectedPath = _fileOpenDialogAPI.getUserSelectedPath(pathPtrPtr);
        hResult = _fileOpenDialogAPI.releaseItem(item);
      });

      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    hResult = _fileOpenDialogAPI.release(dialog);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    CoUninitialize();
    return cancelledByUser ? null : userSelectedPath;
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

      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    return hResult;
  }
}
