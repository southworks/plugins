import 'dart:ffi';

import 'package:win32/win32.dart';

/// FileDialogAdapter
class FileDialogMock extends IFileOpenDialog {
  /// Constructor
  FileDialogMock(Pointer<COMObject> ptr) : super(ptr);
}
