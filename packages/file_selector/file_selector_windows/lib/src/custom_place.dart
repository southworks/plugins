// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:win32/win32.dart';
import 'place.dart';

/// Exposes custom places.
class CustomPlace {
  /// CustomPlace constructor.
  CustomPlace(this.item, this.place);

  /// An IShellItem.
  IShellItem item;

  /// A Place.
  Place place;
}
