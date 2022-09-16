import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// FileOpenDialogAPI Provider.
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

  /// Adds a place to the dialog.
  int addPlace(Pointer<COMObject> psi, int fdap, IFileOpenDialog dialog) {
    return dialog.addPlace(psi, FDAP.FDAP_BOTTOM);
  }

  /// Shows a dialog.
  int show(int hwndOwner, IFileOpenDialog dialog) {
    return dialog.show(hwndOwner);
  }
}
