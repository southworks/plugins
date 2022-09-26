// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:file_selector_windows/src/file_open_dialog_wrapper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

import 'fake_open_file_dialog.dart';

void main() {
  final FileOpenDialogWrapper fileOpenDialogWrapper = FileOpenDialogWrapper();
  final FakeIOpenFileDialog fakeFileOpenDialog = FakeIOpenFileDialog();

  test('getOptions should call dialog getOptions', () {
    final Pointer<Uint32> ptrOptions = calloc<Uint32>();
    fileOpenDialogWrapper.getOptions(ptrOptions, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.getOptionsCalledTimes(), 1);
    free(ptrOptions);
  });

  test('setOptions should call dialog setOptions', () {
    fileOpenDialogWrapper.setOptions(32, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.setOptionsCalledTimes(), 1);
  });

  test('getResult should call dialog getResult', () {
    final Pointer<Pointer<COMObject>> ptrCOMObject =
        calloc<Pointer<COMObject>>();
    fileOpenDialogWrapper.getResult(ptrCOMObject, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.getResultCalledTimes(), 1);
    free(ptrCOMObject);
  });

  test('getResults should call dialog getResults', () {
    final Pointer<Pointer<COMObject>> ptrCOMObject =
        calloc<Pointer<COMObject>>();
    fileOpenDialogWrapper.getResults(ptrCOMObject, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.getResultsCalledTimes(), 1);
    free(ptrCOMObject);
  });

  test('release should call dialog release', () {
    fileOpenDialogWrapper.release(fakeFileOpenDialog);
    expect(fakeFileOpenDialog.releaseCalledTimes(), 1);
  });

  test('setFileName should call dialog setFileName', () {
    fileOpenDialogWrapper.setFileName('name.txt', fakeFileOpenDialog);
    expect(fakeFileOpenDialog.setFileNameCalledTimes(), 1);
  });

  test('setFileTypes should call dialog setFileTypes', () {
    final Map<String, String> filterSpecification = <String, String>{
      'Images': '*.jpg;*.png;',
    };
    fileOpenDialogWrapper.setFileTypes(filterSpecification, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.setFileTypesCalledTimes(), 1);
  });

  test('setFolder should call dialog setFolder', () {
    final Pointer<Pointer<COMObject>> ptrCOMObject =
        calloc<Pointer<COMObject>>();
    fileOpenDialogWrapper.setFolder(ptrCOMObject, fakeFileOpenDialog);
    expect(fakeFileOpenDialog.setFolderCalledTimes(), 1);
    free(ptrCOMObject);
  });

  test(
      'setOkButtonLabelCalledTimes should call dialog setOkButtonLabelCalledTimes',
      () {
    fileOpenDialogWrapper.setOkButtonLabel('text', fakeFileOpenDialog);
    expect(fakeFileOpenDialog.setOkButtonLabelCalledTimes(), 1);
  });
}
