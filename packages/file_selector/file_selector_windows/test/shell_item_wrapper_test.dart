// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/shell_item_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';
import 'shell_item_array_mock.dart';

void main() {
  final ShellItemWrapper shellItemWrapper = ShellItemWrapper();

  setUp(() {});

  tearDown(() {});

  test('creates a shell item instance', () {
    // ignore: unused_element, always_declare_return_types
    using(Arena arena) {
      final Pointer<Pointer<COMObject>> comObjectPtr =
          arena<Pointer<COMObject>>();
      expect(shellItemWrapper.createShellItem(comObjectPtr), isA<IShellItem>());
    }
  });

  test('creates a shell item array instance', () {
    // ignore: unused_element, always_declare_return_types
    using(Arena arena) {
      final Pointer<Pointer<COMObject>> comObjectPtr =
          arena<Pointer<COMObject>>();
      shellItemWrapper.createShellItemArray(comObjectPtr);
      expect(shellItemWrapper.createShellItemArray(comObjectPtr),
          isA<IShellItemArray>());
    }
  });

  test('getCount invokes shellItemArray getCount', () {
    // ignore: unused_element, always_declare_return_types
    using(Arena arena) {
      final FakeIShellItemArray shellItemArray = FakeIShellItemArray();
      final Pointer<Uint32> ptrNumberOfItems = arena<Uint32>();

      shellItemWrapper.getCount(ptrNumberOfItems, shellItemArray);
      verify(shellItemArray.getCount(ptrNumberOfItems));
    }
  });
}
