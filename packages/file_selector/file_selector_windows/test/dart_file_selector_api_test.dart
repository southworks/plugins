// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/dart_file_open_dialog_api.dart';
import 'package:file_selector_windows/src/dart_file_selector_api.dart';
import 'package:file_selector_windows/src/messages.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';
import 'dart_file_selector_api_test.mocks.dart';

@GenerateMocks(<Type>[FileOpenDialogAPI])
void main() {
  const int defaultReturnValue = 1;
  TestWidgetsFlutterBinding.ensureInitialized();
  final MockFileOpenDialogAPI mockFileOpenDialogAPI = MockFileOpenDialogAPI();
  late DartFileSelectorAPI api;
  late Pointer<Uint32> options;
  late int hResult;
  late FileOpenDialog dialog;

  tearDown(() {
    reset(mockFileOpenDialogAPI);
  });

  setUp(() {
    api = DartFileSelectorAPI(mockFileOpenDialogAPI);
    options = calloc<Uint32>();
    hResult = 0;
    api.initializeComLibrary();
    dialog = FileOpenDialog.createInstance();
    when(mockFileOpenDialogAPI.setOptions(any, any))
        .thenReturn(defaultReturnValue);
    when(mockFileOpenDialogAPI.getOptions(any, any))
        .thenReturn(defaultReturnValue);
    when(mockFileOpenDialogAPI.setOkButtonLabel(any, any))
        .thenReturn(defaultReturnValue);
    when(mockFileOpenDialogAPI.setFileTypes(any, any, any))
        .thenReturn(defaultReturnValue);
  });

  test('setDirectoryOptions call dialog setOptions', () {
    const int expectedDirectoryOptions = 2144;
    expect(
        defaultReturnValue, api.setDirectoryOptions(options, hResult, dialog));
    verify(mockFileOpenDialogAPI.setOptions(expectedDirectoryOptions, dialog))
        .called(1);
  });

  test('getOptions should have been called', () {
    final Pointer<Uint32> pfos = calloc<Uint32>();
    expect(defaultReturnValue, api.getOptions(pfos, hResult, dialog));
    verify(mockFileOpenDialogAPI.getOptions(pfos, dialog))
        .called(defaultReturnValue);
  });

  test('addConfirmButtonLabel should call setOkButtonLabel', () {
    const String confirmationText = 'Text';
    expect(defaultReturnValue,
        api.addConfirmButtonLabel(dialog, confirmationText));
    verify(mockFileOpenDialogAPI.setOkButtonLabel(confirmationText, dialog))
        .called(defaultReturnValue);
  });

  test('addFileFilters should call setFileTypes', () {
    final TypeGroup typeGroup =
        TypeGroup(extensions: <String?>['jpg', 'png'], label: 'Images');

    final SelectionOptions selectionOptions = SelectionOptions(
      allowMultiple: true,
      selectFolders: true,
      allowedTypes: <TypeGroup?>[typeGroup],
    );

    final Map<String, String> filterSpecification = <String, String>{
      'Images': '*.jpg;*.png;',
    };

    expect(defaultReturnValue,
        api.addFileFilters(hResult, dialog, selectionOptions));
    verify(mockFileOpenDialogAPI.setFileTypes(
            filterSpecification, hResult, dialog))
        .called(1);
  });

  test(
      'addFileFilters should not call setFileTypes if filterSpecification is empty',
      () {
    final TypeGroup typeGroup =
        TypeGroup(extensions: <String?>[], label: 'Images');

    final SelectionOptions selectionOptions = SelectionOptions(
      allowMultiple: true,
      selectFolders: true,
      allowedTypes: <TypeGroup?>[typeGroup],
    );

    expect(hResult, api.addFileFilters(hResult, dialog, selectionOptions));
    verifyNever(mockFileOpenDialogAPI.setFileTypes(any, hResult, dialog));
  });
}
