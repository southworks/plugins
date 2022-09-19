import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

/// ShellItemApi provider to interact with Shell Items.
class ShellItemAPI {
  /// Create a shell item from a given pointer.
  IShellItem createShellItem(Pointer<Pointer<COMObject>> ppsi) {
    return IShellItem(ppsi.cast());
  }

  /// Creates an array from a given pointer.
  IShellItemArray createShellItemArray(Pointer<Pointer<COMObject>> ppsi) {
    return IShellItemArray(ppsi.cast());
  }

  /// Gets display name for an item.
  int getDisplayName(Pointer<IntPtr> pathPtr, IShellItem item) {
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

  /// Gets the number of elements given a IShellItemArray.
  void getCount(Pointer<Uint32> numberOfSelectedElements,
      IShellItemArray iShellItemArray) {
    iShellItemArray.getCount(numberOfSelectedElements);
  }

  /// Gets the item at a giving position.
  int getItemAt(int i, Pointer<Pointer<COMObject>> item,
      IShellItemArray iShellItemArray) {
    return iShellItemArray.getItemAt(i, item);
  }

  /// Releases the given IShellItemArray.
  void release(IShellItemArray iShellItemArray) {
    iShellItemArray.release();
  }
}
