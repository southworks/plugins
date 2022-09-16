import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter/cupertino.dart';
import 'package:win32/win32.dart';

import 'dart_file_dialog.dart';
import 'dart_file_open_dialog_api.dart';
import 'dart_place.dart';

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

  /// Returns dialog options.
  int getOptions(Pointer<Uint32> pfos, int hResult, IFileOpenDialog dialog) {
    hResult = dialog.getOptions(pfos); // TODO: Use fileDialogAPI
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

  String? _getDirectory({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    int hResult = initializeComLibrary();
    final FileOpenDialog dialog = FileOpenDialog.createInstance();
    final Pointer<Uint32> options = calloc<Uint32>();

    hResult = getOptions(options, hResult, dialog);
    hResult = setDirectoryOptions(options, hResult, dialog);
    addConfirmButtonLabel(dialog, confirmButtonText);
    addCustomPlaces(hResult, dialog);

    hResult = dialog.show(hWndOwner);
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
    bool didUserCancel = false;
    late String userSelectedPath;
    if (FAILED(hResult)) {
      if (hResult == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        didUserCancel = true;
      } else {
        throw WindowsException(hResult);
      }
    } else {
      final Pointer<Pointer<COMObject>> ppsi = calloc<Pointer<COMObject>>();
      hResult = dialog.getResult(ppsi);
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }

      final IShellItem item = IShellItem(ppsi.cast());
      final Pointer<IntPtr> pathPtrPtr = calloc<IntPtr>();
      hResult = item.getDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr.cast());
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }

      final Pointer<Utf16> pathPtr =
          Pointer<Utf16>.fromAddress(pathPtrPtr.value);

      userSelectedPath = pathPtr.toDartString();

      hResult = item.release();
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    hResult = dialog.release();
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    CoUninitialize();
    if (didUserCancel) {
      return null;
    } else {
      return userSelectedPath;
    }
  }

  /// Add confirmation button text.
  @visibleForTesting
  int addConfirmButtonLabel(FileOpenDialog dialog, String? confirmButtonText) {
    return dialog
        .setOkButtonLabel(TEXT(confirmButtonText ?? 'Pick')); // TODO use api
  }

  /// Returns a file.
  String? getFile(SelectionOptions selectionOptions, String? initialDirectory,
      String? confirmButtonText) {
    int hResult = initializeComLibrary();
    final FileOpenDialog fileDialog = FileOpenDialog.createInstance();
    final Pointer<Uint32> options = calloc<Uint32>();
    hResult = getOptions(options, hResult, fileDialog);
    hResult = setFileOptions(options, hResult, fileDialog);
    hResult = addFileFilters(hResult, fileDialog, selectionOptions);
    hResult = addCustomPlaces(hResult, fileDialog);
    hResult = addConfirmButtonLabel(fileDialog, confirmButtonText);
    hResult = fileDialog.show(hWndOwner);
    return returnSelectedElement(hResult, fileDialog);
  }

  /// Adds custom places.
  int addCustomPlaces(int hResult, FileOpenDialog fileDialog) {
    for (final CustomPlace place in customPlaces) {
      final Pointer<NativeType> shellItem =
          Pointer<NativeType>.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hResult = fileDialog.addPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hResult = fileDialog.addPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    return hResult;
  }

  /// Adds file type filters.
  @visibleForTesting
  int addFileFilters(int hResult, FileOpenDialog fileDialog,
      SelectionOptions selectionOptions) {
    for (final TypeGroup? option in selectionOptions.allowedTypes) {
      if (option == null || option.extensions == null) {
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
      final Pointer<COMDLG_FILTERSPEC> rgSpec =
          calloc<COMDLG_FILTERSPEC>(filterSpecification.length);

      int index = 0;
      for (final String key in filterSpecification.keys) {
        rgSpec[index]
          ..pszName = TEXT(key)
          ..pszSpec = TEXT(filterSpecification[key]!);
        index++;
      }
      hResult = fileDialog.setFileTypes(filterSpecification.length, rgSpec);
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    if (defaultFilterIndex != null) {
      if (defaultFilterIndex! > 0 &&
          defaultFilterIndex! < filterSpecification.length) {
        // SetFileTypeIndex is one-based, not zero-based
        hResult = fileDialog.setFileTypeIndex(defaultFilterIndex! + 1);
        if (FAILED(hResult)) {
          throw WindowsException(hResult);
        }
      }
    }

    return hResult;
  }
}
