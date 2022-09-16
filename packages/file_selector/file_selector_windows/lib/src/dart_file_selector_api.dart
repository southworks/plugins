import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'dart_file_dialog.dart';
import 'dart_place.dart';

/// Dart native implementation of FileSelectorAPI
class DartFileSelectorAPI extends FileDialog {
  /// We need the file to exist. This value is default to `false`.
  DartFileSelectorAPI() : super() {
    fileMustExist = true;
  }

  /// Returns directory path from user selection
  String? getDirectoryPath({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    return _getDirectory(
            initialDirectory: initialDirectory,
            confirmButtonText: confirmButtonText)
        ?.path;
  }

  /// Sets the dialog's title.
  int _setDialogTitle(int hResult, FileOpenDialog dialog) {
    if (title.isNotEmpty) {
      hResult = dialog.setTitle(TEXT(title));
      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }
    return hResult;
  }

  /// Sets and checks options for the dialog.
  int _setGetDirectoryOptions(
      Pointer<Uint32> pfos, int hResult, FileOpenDialog dialog) {
    int options = pfos.value;

    options |= FILEOPENDIALOGOPTIONS.FOS_PICKFOLDERS;

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

    hResult = dialog.setOptions(options);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    return hResult;
  }

  int _initializeComLibrary() {
    final int hResult = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }
    return hResult;
  }

  Directory? _getDirectory({
    String? initialDirectory,
    String? confirmButtonText,
  }) {
    bool didUserCancel = false;
    late String userSelectedPath;

    int hResult = _initializeComLibrary();

    final FileOpenDialog dialog = FileOpenDialog.createInstance();

    final Pointer<Uint32> options = calloc<Uint32>();
    hResult = dialog.getOptions(options);
    if (FAILED(hResult)) {
      throw WindowsException(hResult);
    }

    hResult = _setGetDirectoryOptions(options, hResult, dialog);

    hResult = _setDialogTitle(hResult, dialog);
    dialog.setOkButtonLabel(TEXT(confirmButtonText ?? 'Pick'));

    for (final CustomPlace place in customPlaces) {
      final Pointer<NativeType> shellItem =
          Pointer<NativeType>.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hResult = dialog.addPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hResult = dialog.addPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }

      if (FAILED(hResult)) {
        throw WindowsException(hResult);
      }
    }

    hResult = dialog.show(hWndOwner);
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
      // MAX_PATH is the normal maximum, but if the process is set to support
      // long file paths and the user selects a path with length > MAX_PATH
      // characters, it could be longer. In this case, the file name will be
      // truncated.
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
      return Directory(userSelectedPath);
    }
  }
}
