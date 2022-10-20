// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_driver/driver_extension.dart';
import 'get_directory_page.dart';
import 'home_page.dart';
import 'open_image_page.dart';
import 'open_multiple_images_page.dart';
import 'open_text_page.dart';

void main() {
  enableFlutterDriverExtension();
  runApp(const MyApp());
}

/// MyApp is the Main Application.
class MyApp extends StatelessWidget {
  /// Default Constructor
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Selector Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomePage(),
      routes: <String, WidgetBuilder>{
        '/open/text': (BuildContext context) => const OpenTextPage(),
        '/open/image': (BuildContext context) => const OpenImagePage(),
        '/open/images': (BuildContext context) =>
            const OpenMultipleImagesPage(),
        '/directory': (BuildContext context) => const GetDirectoryPage(),
      },
    );
  }
}
