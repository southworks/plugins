// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_windows/src/file_selector_dart/dialog_mode.dart';
import 'package:file_selector_windows/src/file_selector_dart/dialog_wrapper.dart';
import 'package:file_selector_windows/src/file_selector_dart/file_dialog_controller.dart';
import 'package:file_selector_windows/src/file_selector_dart/file_dialog_controller_factory.dart';
import 'package:file_selector_windows/src/file_selector_dart/ifile_dialog_factory.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:win32/win32.dart';

import 'dialog_wrapper_test.mocks.dart';

@GenerateMocks(<Type>[FileDialogController])
void main() {
  const int defaultReturnValue = S_OK;
  late final MockFileDialogController mockFileDialogController =
      MockFileDialogController();
  final FileDialogControllerFactory fileDialogControllerFactory =
      FileDialogControllerFactory();
  final IFileDialogFactory fileDialogFactory = IFileDialogFactory();
  const DialogMode dialogMode = DialogMode.Open;
  final DialogWrapper dialogWrapper = DialogWrapper.withFakeDependencies(
      mockFileDialogController,
      fileDialogControllerFactory,
      fileDialogFactory,
      dialogMode);

  setUp(() {
    setDefaultMocks(mockFileDialogController, defaultReturnValue);
  });

  tearDown(() {
    reset(mockFileDialogController);
  });

  test('setFileName should call dialog setFileName', () {
    const String folderName = 'Documents';
    dialogWrapper.setFileName(folderName);
    verify(mockFileDialogController.setFileName(folderName)).called(1);
  });

  test('setOkButtonLabel should call dialog setOkButtonLabel', () {
    const String okButtonLabel = 'Confirm';
    dialogWrapper.setOkButtonLabel(okButtonLabel);
    verify(mockFileDialogController.setOkButtonLabel(okButtonLabel)).called(1);
  });

  test('addOptions should call dialog getOptions and setOptions', () {
    const int newOptions = FILEOPENDIALOGOPTIONS.FOS_NOREADONLYRETURN;
    dialogWrapper.addOptions(newOptions);
    verify(mockFileDialogController.getOptions(any)).called(1);
    verify(mockFileDialogController.setOptions(newOptions)).called(1);
  });

  test('addOptions should not call setOptions if getOptions returns an error',
      () {
    const int options = FILEOPENDIALOGOPTIONS.FOS_NOREADONLYRETURN;
    when(mockFileDialogController.getOptions(any)).thenReturn(E_FAIL);
    dialogWrapper.addOptions(options);
    verifyNever(mockFileDialogController.setOptions(any));
  });
}

void setDefaultMocks(
    MockFileDialogController mockFileDialogController, int defaultReturnValue) {
  when(mockFileDialogController.setOptions(any)).thenReturn(defaultReturnValue);
  when(mockFileDialogController.getOptions(any)).thenReturn(defaultReturnValue);
  when(mockFileDialogController.setOkButtonLabel(any))
      .thenReturn(defaultReturnValue);
  when(mockFileDialogController.setFileName(any))
      .thenReturn(defaultReturnValue);
}
