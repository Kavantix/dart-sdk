// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as p;

/// For commands where we are able to initialize the [ArgParser], this value
/// is used as the usageLineLength.
int get dartdevUsageLineLength =>
    stdout.hasTerminal ? stdout.terminalColumns : null;

/// Given a data structure which is a Map of String to dynamic values, return
/// the same structure (`Map<String, dynamic>`) with the correct runtime types.
Map<String, dynamic> castStringKeyedMap(dynamic untyped) {
  final Map<dynamic, dynamic> map = untyped as Map<dynamic, dynamic>;
  return map?.cast<String, dynamic>();
}

/// Emit the given word with the correct pluralization.
String pluralize(String word, int count) => count == 1 ? word : '${word}s';

/// Make an absolute [filePath] relative to [dir] (for display purposes).
String relativePath(String filePath, Directory dir) {
  var root = dir.absolute.path;
  if (filePath.startsWith(root)) {
    return filePath.substring(root.length + 1);
  }
  return filePath;
}

/// String utility to trim some suffix from the end of a [String].
String trimEnd(String s, String suffix) {
  if (s != null && suffix != null && suffix.isNotEmpty && s.endsWith(suffix)) {
    return s.substring(0, s.length - suffix.length);
  }
  return s;
}

extension FileSystemEntityExtension on FileSystemEntity {
  String get name => p.basename(path);

  bool get isDartFile => this is File && p.extension(path) == '.dart';
}
