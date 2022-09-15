// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  input: 'pigeons/messages.dart',
  javaOut:
      'android/src/main/java/io/flutter/plugins/file_selector/Messages.java',
  javaOptions: JavaOptions(
      className: 'Messages', package: 'io.flutter.plugins.file_selector'),
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
class TypeGroup {
  TypeGroup(this.label, {required this.extensions});

  String label;
  List<String?> extensions;
}

class SelectionOptions {
  SelectionOptions({
    this.allowMultiple = false,
    this.selectFolders = false,
    this.allowedTypes = const <TypeGroup?>[],
  });
  bool allowMultiple;
  bool selectFolders;

  List<TypeGroup?> allowedTypes;
}

enum FileSelectorMethod { OPEN_FILE, GET_DIRECTORY_PATH, OPEN_MULTIPLE_FILES }

@HostApi(dartHostTestHandler: 'TestFileSelectorApi')
abstract class FileSelectorApi {
  List<String?> startFileExplorer(
    FileSelectorMethod method,
    SelectionOptions options,
    String? initialDirectory,
    String? confirmButtonText,
  );

  String? openSaveDialog(
    SelectionOptions options,
    String? initialDirectory,
    String? confirmButtonText,
    String? suggestedName,
  );
}
