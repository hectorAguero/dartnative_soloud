// DartNative fork: the upstream file tells the Android FlutterSoloudPlugin,
// over a Flutter MethodChannel, that this isolate uses the native library, so
// the plugin tears the native engine down with its FlutterEngine. DartNative
// has no FlutterEngine, no platform channels and does not build the Android
// plugin, so the bridge reports itself unsupported and teardown is left to an
// explicit `deinit()`, as with `darwin_engine_lifecycle.dart`.
//
// The public shape is kept so `soloud.dart` stays as upstream.

/// Stand-in for the upstream bridge over the Android plugin's
/// engine-lifecycle channel. Never supported on DartNative.
class AndroidEngineLifecycle {
  /// Creates the stand-in.
  const AndroidEngineLifecycle();

  /// The upstream channel name, kept for reference.
  static const String channelName = 'flutter_soloud/engine_lifecycle';

  /// The upstream method name, kept for reference.
  static const String methodName = 'nativeLibraryInUse';

  /// Always false: there is no Android plugin to tell on DartNative.
  static bool get isSupported => false;

  /// Always false, so the caller never sends the signal.
  static bool get isPending => false;

  /// Nothing to forget.
  static void debugReset() {}

  /// Always false: nothing is sent.
  Future<bool> markNativeLibraryInUse() async => false;
}
