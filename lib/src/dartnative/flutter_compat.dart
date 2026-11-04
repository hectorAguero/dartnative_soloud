// DartNative compatibility layer.
//
// DartNative apps run without the Flutter framework: the SDK's
// `package:flutter` is a stub that only has `kIsWeb` and a few annotations.
// This file provides, on top of `package:dartnative`, the handful of Flutter
// names flutter_soloud uses, so the upstream sources only swap their
// `package:flutter/*` imports for this one. Keep it that way: the smaller the
// diff against upstream, the easier each rebase.

import 'dart:async';
import 'dart:io' show Platform;
import 'dart:isolate';
import 'dart:typed_data';

import 'package:dartnative/dartnative.dart' as dn;

export 'dart:typed_data';
export 'package:dartnative/dartnative.dart' show debugPrint;
export 'package:meta/meta.dart';

/// Mirror of Flutter's `ComputeCallback`.
typedef ComputeCallback<M, R> = FutureOr<R> Function(M message);

/// Mirror of Flutter's `compute`: runs [callback] on a short-lived isolate,
/// as Flutter does with `Isolate.run`.
///
/// Not DartNative's `compute`. That one runs on a background pool whose
/// isolates stay alive between calls, and a hot restart sometimes hangs for
/// good while `dn` kills them (DartNative 1.5.0, reproduced with no SoLoud
/// code involved). An isolate from `Isolate.run` is gone once its load
/// finishes, so a restart has nothing to kill.
Future<R> compute<M, R>(
  ComputeCallback<M, R> callback,
  M message, {
  String? debugLabel,
}) => Isolate.run(() => callback(message), debugName: debugLabel ?? 'compute');

/// DartNative runs on iOS and Android only, never on the web.
const bool kIsWeb = false;

/// Mirror of Flutter's `TargetPlatform`.
enum TargetPlatform { android, fuchsia, iOS, linux, macOS, windows }

/// Mirror of Flutter's `defaultTargetPlatform`, read from `dart:io`.
TargetPlatform get defaultTargetPlatform {
  if (Platform.isIOS) return TargetPlatform.iOS;
  if (Platform.isAndroid) return TargetPlatform.android;
  if (Platform.isMacOS) return TargetPlatform.macOS;
  if (Platform.isWindows) return TargetPlatform.windows;
  if (Platform.isFuchsia) return TargetPlatform.fuchsia;
  return TargetPlatform.linux;
}

/// Minimal mirror of Flutter's `AssetBundle`: the only member flutter_soloud
/// calls is [load].
// ignore: one_member_abstracts
abstract class AssetBundle {
  /// Loads the bytes of the asset at [key], e.g. `assets/sound.mp3`.
  Future<ByteData> load(String key);
}

/// The app's bundled assets, read through DartNative's `loadAssetBytes`.
final AssetBundle rootBundle = _DartNativeAssetBundle();

class _DartNativeAssetBundle implements AssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = dn.loadAssetBytes(key);
    if (bytes == null) {
      // Flutter throws a FlutterError here; there is no such type without
      // Flutter, so throw the closest standard error with the same message.
      throw StateError('Unable to load asset: "$key".');
    }
    return ByteData.sublistView(bytes);
  }

  @override
  String toString() => 'rootBundle (DartNative)';
}
