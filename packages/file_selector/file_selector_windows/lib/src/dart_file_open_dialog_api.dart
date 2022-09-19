import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// FileOpenDialogAPI provider, it used to interact with an IFileOpenDialogInstance.
class FileOpenDialogAPI {
  /// Sets dialog options.
  int setOptions(int fos, IFileOpenDialog dialog) {
    return dialog.setOptions(fos);
  }

  /// Returns dialog options.
  int getOptions(Pointer<Uint32> fos, IFileOpenDialog dialog) {
    return dialog.getOptions(fos);
  }

  /// Set confirmation button text on dialog.
  int setOkButtonLabel(String? confirmationText, IFileOpenDialog dialog) {
    return dialog.setOkButtonLabel(TEXT(confirmationText ?? 'Pick'));
  }

  /// Sets allowed file type extensions.
  int setFileTypes(Map<String, String> filterSpecification, int hResult,
      IFileOpenDialog dialog) {
    if (filterSpecification.isEmpty) {
      return hResult;
    }

    final Pointer<COMDLG_FILTERSPEC> rgSpec =
        calloc<COMDLG_FILTERSPEC>(filterSpecification.length);

    int index = 0;
    for (final String key in filterSpecification.keys) {
      rgSpec[index]
        ..pszName = TEXT(key)
        ..pszSpec = TEXT(filterSpecification[key]!);
      index++;
    }

    hResult = dialog.setFileTypes(filterSpecification.length, rgSpec);
    return hResult;
  }

  /// Shows a dialog.
  int show(int hwndOwner, IFileOpenDialog dialog) {
    return dialog.show(hwndOwner);
  }

  /// Release a dialog.
  int release(IFileOpenDialog dialog) {
    return dialog.release();
  }

  /// Return a result from a dialog.
  int getResult(Pointer<Pointer<COMObject>> ppsi, IFileOpenDialog dialog) {
    return dialog.getResult(ppsi);
  }

  /// Gets display name for an item.
  int getDisplayName(IShellItem item, Pointer<IntPtr> pathPtr) {
    return item.getDisplayName(SIGDN.SIGDN_FILESYSPATH, pathPtr.cast());
  }

  /// Returns the selected path by the user.
  String getUserSelectedPath(Pointer<IntPtr> pathPtrPtr) {
    final Pointer<Utf16> pathPtr = Pointer<Utf16>.fromAddress(pathPtrPtr.value);
    return pathPtr.toDartString();
  }

  /// Releases an IShellItem.
  int releaseItem(IShellItem item) {
    return item.release();
  }
}
