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
  dartOut: 'lib/messages.g.dart',
  dartTestOut: 'test/messages_test.g.dart',
  copyrightHeader: 'pigeons/copyright.txt',
))
class TypeGroup {
  TypeGroup(this.label, {required this.extensions, required this.mimeTypes});

  String label;
  List<String?> extensions;
  List<String?> mimeTypes;
}

class SelectionOptions {
  SelectionOptions({
    this.allowMultiple = false,
    this.allowedTypes = const <TypeGroup?>[],
  });
  bool allowMultiple;

  List<TypeGroup?> allowedTypes;
}

@HostApi(dartHostTestHandler: 'TestFileSelectorApi')
abstract class FileSelectorApi {
  List<String?> openFiles(
    SelectionOptions options,
    String? initialDirectory,
    String? confirmButtonText,
  );
  String? getDirectoryPath(
    String? initialDirectory,
  );
}
