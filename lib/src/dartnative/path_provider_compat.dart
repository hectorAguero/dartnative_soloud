// DartNative replacement for the part of `package:path_provider` that
// flutter_soloud uses. DartNative's provider is synchronous and returns a
// path; this keeps the upstream call site (`await getTemporaryDirectory()`)
// unchanged.

import 'dart:io';

import 'package:dartnative_path_provider/dartnative_path_provider.dart' as dn;

/// The app's temporary directory.
Future<Directory> getTemporaryDirectory() async =>
    Directory(dn.getTemporaryDirectory());
