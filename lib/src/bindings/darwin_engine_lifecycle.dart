// DartNative fork: the upstream file asks the iOS/macOS FlutterSoloudPlugin,
// over a Flutter MethodChannel, to adopt the FlutterEngine id and arm teardown
// when that engine goes away. DartNative has no FlutterEngine and no platform
// channels, so the bridge reports itself unsupported: the FFI bindings then
// claim the native engine directly, as they do on Linux and Windows, and
// teardown is left to an explicit `deinit()`.
//
// The public shape is kept so `bindings_player_ffi.dart` stays as upstream.

/// What came of asking the iOS plugin to claim the native engine.
enum DarwinEnginePrepareResult {
  /// The plugin took the native lifecycle claim.
  claimed,

  /// The channel could not be used at all, so nothing was claimed. The caller
  /// must take the claim itself.
  unavailable,

  /// The plugin refused, or the outcome of a sent request is unknown.
  refused,
}

/// Stand-in for the upstream bridge over the plugin's engine-lifecycle
/// channel. Never supported on DartNative.
class DarwinEngineLifecycle {
  /// Creates the stand-in.
  const DarwinEngineLifecycle();

  /// The upstream channel name, kept for reference.
  static const String channelName = 'flutter_soloud/engine_lifecycle';

  /// Always false: there is no FlutterEngine to observe on DartNative.
  static bool get isSupported => false;

  /// Always [DarwinEnginePrepareResult.unavailable], so the caller claims the
  /// engine directly.
  Future<DarwinEnginePrepareResult> prepareEngineInit(
    int engineId,
    int shutdownEpoch,
  ) async => DarwinEnginePrepareResult.unavailable;
}
