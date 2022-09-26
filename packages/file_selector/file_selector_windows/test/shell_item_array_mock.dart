// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

// Fake IShellItemArray class
class FakeIShellItemArray extends Fake implements IShellItemArray {
  @override
  int getCount(Pointer<Uint32> ptrCount) {
    return 0;
  }
}
