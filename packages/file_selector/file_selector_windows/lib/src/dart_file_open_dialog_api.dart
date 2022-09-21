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
  int getResult(
      Pointer<Pointer<COMObject>> ptrCOMObject, IFileOpenDialog dialog) {
    return dialog.getResult(ptrCOMObject);
  }

  /// Return results from a dialog, this should be used when selecting multiple items.
  int getResults(
      Pointer<Pointer<COMObject>> ptrCOMObject, IFileOpenDialog dialog) {
    return dialog.getResults(ptrCOMObject);
  }

  /// Sets the initial directory for a dialog.
  int setFolder(Pointer<Pointer<COMObject>> ptrPath, IFileOpenDialog dialog) {
    return dialog.setFolder(ptrPath.value);
  }

  /// Sets the file name for a dialog.
  int setFileName(String suggestedFileName, IFileOpenDialog dialog) {
    return dialog.setFileName(TEXT(suggestedFileName));
  }

  /// Creates item from a given initial directory. This throws if the directory does not exist.
  int createItemFromParsingName(String initialDirectory, Pointer<GUID> ptrGuid,
      Pointer<Pointer<NativeType>> ptrPath) {
    return SHCreateItemFromParsingName(
        TEXT(initialDirectory), nullptr, ptrGuid, ptrPath);
  }
}
