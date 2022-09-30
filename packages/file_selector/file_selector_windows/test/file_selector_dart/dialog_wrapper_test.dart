// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file_selector_windows/src/file_selector_dart/dialog_mode.dart';
import 'package:file_selector_windows/src/file_selector_dart/dialog_wrapper.dart';
import 'package:file_selector_windows/src/file_selector_dart/file_dialog_controller.dart';
import 'package:file_selector_windows/src/file_selector_dart/file_dialog_controller_factory.dart';
import 'package:file_selector_windows/src/file_selector_dart/ifile_dialog_factory.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_file_dialog.dart';
import 'fake_ifile_open_dialog_factory.dart';

void main() {
  final FakeIFileDialog fakeFileOpenDialog = FakeIFileDialog();
  final FakeIFileOpenDialogFactory fakeIFileOpenDialogFactory =
      FakeIFileOpenDialogFactory();
  final FileDialogController fileDialogController =
      FileDialogController(fakeFileOpenDialog, fakeIFileOpenDialogFactory);
  final FileDialogControllerFactory fileDialogControllerFactory =
      FileDialogControllerFactory();
  final IFileDialogFactory fileDialogFactory = IFileDialogFactory();
  const DialogMode dialogMode = DialogMode.Open;
  final DialogWrapper dialogWrapper = DialogWrapper.test(
      fileDialogController,
      fileDialogControllerFactory,
      fileDialogFactory,
      DialogMode.Open,
      dialogMode == DialogMode.Open);

  setUp(() {});

  tearDown(() {});

  test('setFileName call dialog setFileName', () {
    const String folderName = 'Documents';
    dialogWrapper.setFileName(folderName);
    expect(fakeFileOpenDialog.setFileNameCalledTimes(), 1);
  });

  test('setOkButtonLabel call dialog setOkButtonLabel', () {
    const String okButtonLabel = 'Confirm';
    dialogWrapper.setOkButtonLabel(okButtonLabel);
    expect(fakeFileOpenDialog.setOkButtonLabelCalledTimes(), 1);
  });
}
