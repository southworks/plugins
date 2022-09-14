import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

import 'dart_file_dialog.dart';
import 'dart_place.dart';

/// Dart native implementation of FileSelectorAPI
class OpenFilePicker extends FileDialog {
  /// We need the file to exist. This value is default to `false`.
  OpenFilePicker() : super() {
    fileMustExist = true;
  }

  /// Indicates to the Open dialog box that the preview pane should always be
  /// displayed.
  bool? forcePreviewPaneOn;

  /// Returns a `File` object from the selected file path.
  File? getFile() {
    bool didUserCancel = false;
    late String filePath;

    int hr = initializeComLibrary();

    final FileOpenDialog fileDialog = FileOpenDialog.createInstance();

    final Pointer<Uint32> pfos = calloc<Uint32>();
    hr = fileDialog.getOptions(pfos);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    hr = setOpenFileOptions(pfos, hr, fileDialog);

    if (defaultExtension != null && defaultExtension!.isNotEmpty) {
      hr = fileDialog.setDefaultExtension(TEXT(defaultExtension!));
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    if (fileName.isNotEmpty) {
      hr = fileDialog.setFileName(TEXT(fileName));
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    if (fileNameLabel.isNotEmpty) {
      hr = fileDialog.setFileNameLabel(TEXT(fileNameLabel));
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    if (title.isNotEmpty) {
      hr = fileDialog.setTitle(TEXT(title));
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
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
      hr = fileDialog.setFileTypes(filterSpecification.length, rgSpec);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    if (defaultFilterIndex != null) {
      if (defaultFilterIndex! > 0 &&
          defaultFilterIndex! < filterSpecification.length) {
        // SetFileTypeIndex is one-based, not zero-based
        hr = fileDialog.setFileTypeIndex(defaultFilterIndex! + 1);
        if (FAILED(hr)) {
          throw WindowsException(hr);
        }
      }
    }

    for (final CustomPlace place in customPlaces) {
      final Pointer<NativeType> shellItem =
          Pointer.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hr = fileDialog.addPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hr = fileDialog.addPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    hr = fileDialog.show(hWndOwner);
    if (FAILED(hr)) {
      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        didUserCancel = true;
      } else {
        throw WindowsException(hr);
      }
    } else {
      final Pointer<Pointer<COMObject>> ppsi = calloc<Pointer<COMObject>>();
      hr = fileDialog.getResult(ppsi);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      final IShellItem item = IShellItem(ppsi.cast());
      final Pointer<Pointer<Utf16>> pathPtrPtr = calloc<Pointer<Utf16>>();
      hr = item.getDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      filePath = pathPtrPtr.value.toDartString();

      hr = item.release();
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    hr = fileDialog.release();
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    CoUninitialize();
    if (didUserCancel) {
      return null;
    } else {
      return File(filePath);
    }
  }

  /// Sets and checks the options for the file dialog.
  int setOpenFileOptions(
      Pointer<Uint32> pfos, int hr, FileOpenDialog fileDialog) {
    int options = pfos.value;
    if (hidePinnedPlaces) {
      options |= FILEOPENDIALOGOPTIONS.FOS_HIDEPINNEDPLACES;
    }
    if (forcePreviewPaneOn ?? false) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEPREVIEWPANEON;
    }
    if (forceFileSystemItems) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FORCEFILESYSTEM;
    }
    if (fileMustExist) {
      options |= FILEOPENDIALOGOPTIONS.FOS_FILEMUSTEXIST;
    }
    if (isDirectoryFixed) {
      options |= FILEOPENDIALOGOPTIONS.FOS_NOCHANGEDIR;
    }

    hr = fileDialog.setOptions(options);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }
    return hr;
  }

  int initializeComLibrary() {
    final int hr = CoInitializeEx(
        nullptr, COINIT_APARTMENTTHREADED | COINIT_DISABLE_OLE1DDE);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }
    return hr;
  }

  Directory? getDirectory() {
    bool didUserCancel = false;
    late String path;

    int hr = initializeComLibrary();

    final FileOpenDialog dialog = FileOpenDialog.createInstance();

    final Pointer<Uint32> pfos = calloc<Uint32>();
    hr = dialog.getOptions(pfos);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    hr = setGetDirectoryOptions(pfos, hr, dialog);

    if (title.isNotEmpty) {
      hr = dialog.setTitle(TEXT(title));
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    for (final CustomPlace place in customPlaces) {
      final Pointer<NativeType> shellItem =
          Pointer.fromAddress(place.item.ptr.cast<IntPtr>().value);
      if (place.place == Place.bottom) {
        hr = dialog.addPlace(shellItem.cast(), FDAP.FDAP_BOTTOM);
      } else {
        hr = dialog.addPlace(shellItem.cast(), FDAP.FDAP_TOP);
      }
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    hr = dialog.show(hWndOwner);
    if (FAILED(hr)) {
      if (hr == HRESULT_FROM_WIN32(ERROR_CANCELLED)) {
        didUserCancel = true;
      } else {
        throw WindowsException(hr);
      }
    } else {
      final Pointer<Pointer<COMObject>> ppsi = calloc<Pointer<COMObject>>();
      hr = dialog.getResult(ppsi);
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      final IShellItem item = IShellItem(ppsi.cast());
      final Pointer<IntPtr> pathPtrPtr = calloc<IntPtr>();
      hr = item.getDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtrPtr.cast());
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }

      final Pointer<Utf16> pathPtr =
          Pointer<Utf16>.fromAddress(pathPtrPtr.value);
      // MAX_PATH is the normal maximum, but if the process is set to support
      // long file paths and the user selects a path with length > MAX_PATH
      // characters, it could be longer. In this case, the file name will be
      // truncated.
      path = pathPtr.toDartString();

      hr = item.release();
      if (FAILED(hr)) {
        throw WindowsException(hr);
      }
    }

    hr = dialog.release();
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }

    CoUninitialize();
    if (didUserCancel) {
      return null;
    } else {
      return Directory(path);
    }
  }

  /// Sets and checks options for the dialog.
  int setGetDirectoryOptions(
      Pointer<Uint32> pfos, int hr, FileOpenDialog dialog) {
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

    hr = dialog.setOptions(options);
    if (FAILED(hr)) {
      throw WindowsException(hr);
    }
    return hr;
  }
}
