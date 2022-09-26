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
import 'shell_item_mock.dart';

void main() {
  final ShellItemWrapper shellItemWrapper = ShellItemWrapper();

  setUp(() {});

  tearDown(() {});

  test('creates a shell item instance', () {
    final Pointer<Pointer<COMObject>> ptrComObject =
        calloc<Pointer<COMObject>>();
    expect(shellItemWrapper.createShellItem(ptrComObject), isA<IShellItem>());
    free(ptrComObject);
  });

  test('creates a shell item array instance', () {
    final Pointer<Pointer<COMObject>> ptrComObject =
        calloc<Pointer<COMObject>>();
    shellItemWrapper.createShellItemArray(ptrComObject);
    expect(shellItemWrapper.createShellItemArray(ptrComObject),
        isA<IShellItemArray>());
    free(ptrComObject);
  });

  test('getCount invokes shellItemArray getCount', () {
    final FakeIShellItemArray shellItemArray = FakeIShellItemArray();
    final Pointer<Uint32> ptrNumberOfItems = calloc<Uint32>();

    shellItemWrapper.getCount(ptrNumberOfItems, shellItemArray);
    expect(1, shellItemArray.getCountCalledTimes());
    free(ptrNumberOfItems);
  });

  test('getDisplayName invokes shellItem getDisplayName', () {
    final FakeIShellItem shellItem = FakeIShellItem();
    final Pointer<IntPtr> ptrInt = calloc<IntPtr>();

    shellItemWrapper.getDisplayName(ptrInt, shellItem);
    expect(1, shellItem.getDisplayNameCalledTimes());
    free(ptrInt);
  });

  test('getItemAt invokes shellItem getItemAt', () {
    final FakeIShellItemArray shellItemArray = FakeIShellItemArray();
    final Pointer<Uint32> ptrNumberOfItems = calloc<Uint32>();
    final Pointer<Pointer<COMObject>> ptrShellItem =
        calloc<Pointer<COMObject>>();

    shellItemWrapper.getItemAt(4, ptrShellItem, shellItemArray);
    expect(1, shellItemArray.getItemAtCalledTimes());
    free(ptrNumberOfItems);
    free(ptrShellItem);
  });
}
