// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:win32/win32.dart';

// Fake IOpenFileDialog class
class FakeIOpenFileDialog extends Fake implements IFileOpenDialog {
  int _getOptionsCalledTimes = 0;
  int _getResultCalledTimes = 0;
  int _getResultsCalledTimes = 0;
  int _setOptionsCalledTimes = 0;
  int _setFileNameCalledTimes = 0;
  int _setFileTypesCalledTimes = 0;
  int _releaseCalledTimes = 0;
  int _setFolderCalledTimes = 0;
  int _setOkButtonLabelCalledTimes = 0;

  @override
  int getOptions(Pointer<Uint32> pfos) {
    _getOptionsCalledTimes++;
    return 0;
  }

  @override
  int setOptions(int options) {
    _setOptionsCalledTimes++;
    return 0;
  }

  @override
  int getResult(Pointer<Pointer<COMObject>> ppsi) {
    _getResultCalledTimes++;
    return 0;
  }

  @override
  int getResults(Pointer<Pointer<COMObject>> ppsi) {
    _getResultsCalledTimes++;
    return 0;
  }

  @override
  int release() {
    _releaseCalledTimes++;
    return 0;
  }

  @override
  int setFileTypes(int cFileTypes, Pointer<COMDLG_FILTERSPEC> rgFilterSpec) {
    _setFileTypesCalledTimes++;
    return 0;
  }

  @override
  int setFileName(Pointer<Utf16> pszName) {
    _setFileNameCalledTimes++;
    return 0;
  }

  @override
  int setFolder(Pointer<COMObject> psi) {
    _setFolderCalledTimes++;
    return 0;
  }

  @override
  int setOkButtonLabel(Pointer<Utf16> pszText) {
    _setOkButtonLabelCalledTimes++;
    return 0;
  }

  int getOptionsCalledTimes() {
    return _getOptionsCalledTimes;
  }

  int setOptionsCalledTimes() {
    return _setOptionsCalledTimes;
  }

  int getResultCalledTimes() {
    return _getResultCalledTimes;
  }

  int getResultsCalledTimes() {
    return _getResultsCalledTimes;
  }

  int releaseCalledTimes() {
    return _releaseCalledTimes;
  }

  int setFileNameCalledTimes() {
    return _setFileNameCalledTimes;
  }

  int setFileTypesCalledTimes() {
    return _setFileTypesCalledTimes;
  }

  int setFolderCalledTimes() {
    return _setFolderCalledTimes;
  }

  int setOkButtonLabelCalledTimes() {
    return _setOkButtonLabelCalledTimes;
  }
}
