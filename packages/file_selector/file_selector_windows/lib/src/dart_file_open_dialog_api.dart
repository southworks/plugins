import 'package:win32/win32.dart';

/// FileOpenDialogAPI Provider.
class FileOpenDialogAPI {
  /// Sets dialog options.
  int setOptions(int fos, IFileOpenDialog dialog) {
    return dialog.setOptions(fos);
  }
}
