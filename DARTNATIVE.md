# DartNative fork

This repository is a fork of [alnitak/flutter_soloud](https://github.com/alnitak/flutter_soloud)
that runs on [DartNative](https://dartnative.com) (iOS and Android). DartNative
has no Flutter framework, only a stub `package:flutter`, so the fork carries a
small patch on top of upstream. This file explains how to use it, lists that
patch, and how to keep it current.

## Using it in a DartNative app

Add the fork from git, pinned to a release tag:

```yaml
# your_app/pubspec.yaml
dependencies:
  flutter_soloud:
    git:
      url: https://github.com/hectorAguero/dartnative_soloud
      ref: v5.2.2-dn.1
```

Then run `dn pub get`. The API is upstream's, including the import
(`package:flutter_soloud/flutter_soloud.dart`), so
[upstream's docs](https://github.com/alnitak/flutter_soloud#readme) apply.
SoLoud's native code is built by `hook/build.dart` when the app builds. Keep
the `DartNativePluginRegistrant.registerAll()` line that `dn create` puts in
`main()`: it sets up `dartnative_path_provider`, which gives the package's
loader its temporary folder.

**DartNative 1.5.0 needs one workaround on Android.** On affected versions
([DartNative#83](https://github.com/DartNative/dartnative/issues/83),
reported on 1.5.0 and fixed in 1.5.1), every Android build after the first fails with
`mergeDebugJniLibFolders uses this output of task compileFlutterBuildDebug`.
Upgrade DartNative, or add this to the end of your app's
`android/app/build.gradle.kts`:

```kotlin
afterEvaluate {
    listOf("Debug", "Profile", "Release").forEach { variant ->
        val compile = tasks.findByName("compileFlutterBuild$variant") ?: return@forEach
        tasks.findByName("merge${variant}JniLibFolders")?.dependsOn(compile)
    }
}
```

`dn_example/` is a working app that uses the package; its `main.dart` plays a
tone, an MP3 asset and an Opus asset.

**Why git and not dartpub.dev:** `dn publish` packages only `lib/`, the
pubspec and the docs, plus native code written as `ios/Classes` sources or an
Android plugin module. SoLoud's C++ comes from a build hook, which it leaves
out, so a dartpub.dev release would have no audio engine in it. Git
dependencies run the hook, as path and pub.dev dependencies do. The fork moves
to dartpub.dev once DartNative can ship build-hook packages there.

## Releases

Tags are `v<upstream version>-dn.<n>`: the upstream release the fork is
based on, and the fork's own revision of it, starting at 1. `pubspec.yaml`
keeps upstream's version. Each tag has a GitHub release with its notes.

| Tag | Upstream | Notes |
|---|---|---|
| `v5.2.2-dn.1` | 5.2.2 | First DartNative release. Hot restart is safe while sounds play. |

## The patch

Everything else is upstream, untouched.

| File | Change | On a merge conflict |
|---|---|---|
| `lib/src/dartnative/flutter_compat.dart` | New. Provides the Flutter names the package uses (`kIsWeb`, `defaultTargetPlatform`, `debugPrint`, `compute`, `rootBundle`, typed data, `meta`) on top of `package:dartnative`. `compute` is `Isolate.run`, as in Flutter, not DartNative's (see below). | Fork-only, no conflicts. Add to it when upstream starts using another Flutter API. |
| `lib/src/dartnative/path_provider_compat.dart` | New. `getTemporaryDirectory()` over `dartnative_path_provider`. | Fork-only. |
| `soloud.dart`, `filters/filters.dart`, `filters/parametric_eq.dart`, `filters/custom_filter.dart`, `vst3/vst3_host_ffi.dart`, `vst3/vst3_host_web.dart`, `utils/loader_base.dart`, `utils/loader_io.dart`, `utils/loader_web.dart` | `package:flutter/*` imports (and `path_provider` in `loader_io.dart`) replaced by the compat imports. Nothing else. | Take upstream's file, then swap the imports again. |
| `bindings/darwin_engine_lifecycle.dart` | Rewritten as a stub that is never supported (no FlutterEngine, no MethodChannel). | Keep ours. If upstream changes the class's public API, mirror it in the stub. |
| `bindings/android_engine_lifecycle.dart` | Rewritten as a stub that is never supported (no FlutterEngine, no MethodChannel, no Android plugin). | Keep ours. If upstream changes the class's public API, mirror it in the stub. |
| `bindings/bindings_player_ffi.dart` | No `dart:ui`; `currentEngineId` always returns `noEngineId`. | Take upstream's file, then remove `dart:ui` and restore the one-line getter. |
| `pubspec.yaml` | Drops `flutter`, `flutter_test`, `path_provider`, `plugin_platform_interface` and the `flutter:` plugin/assets block; adds `dartnative`, `dartnative_path_provider`. Keeps `web: ^1.1.0`: `web` 1.1.2 needs Dart 3.13, newer than the DartNative SDK's. | Take upstream's version and new dependencies, keep ours for everything listed here. |
| `README.md` | A note at the top pointing to this file. | Keep upstream's README and the note above it. |
| `dn_example/`, `DARTNATIVE.md`, `tool/dartnative_check.sh` | Fork-only. | — |

Rules that keep the patch small:

- **Don't delete upstream files** (web, desktop, the Flutter `example/`,
  `android/`, `ios/`). DartNative never builds them, and deleting them turns
  every upstream edit to them into a modify/delete conflict.
- **Don't rename the package in the source.** Every file imports
  `package:flutter_soloud/…`, so a rename would conflict on every sync. Apps
  depend on it as `flutter_soloud` from git.
- **Route new Flutter APIs through `flutter_compat.dart`** rather than editing
  upstream code.

## Syncing with upstream

Two branches:

- **`main`** mirrors upstream exactly. Never commit to it; keep it current with
  GitHub's "Sync fork" button or `gh repo sync hectorAguero/dartnative_soloud`.
- **`dartnative`** is the DartNative version: the default branch, and where
  release tags go. `git diff main dartnative` is always the whole patch.

Merge (don't rebase) each upstream release into `dartnative`, so every
conflict is resolved once:

```bash
gh repo sync hectorAguero/dartnative_soloud   # main ← upstream
git fetch origin --tags
git switch -c sync/vX.Y.Z origin/dartnative
git merge vX.Y.Z            # resolve conflicts with the table above
tool/dartnative_check.sh --build
git push -u origin sync/vX.Y.Z   # open a PR into dartnative
```

Once the PR is merged, tag the release and add it to the Releases table:

```bash
git switch dartnative && git pull
git tag -a vX.Y.Z-dn.1 -m "flutter_soloud X.Y.Z for DartNative"
git push origin vX.Y.Z-dn.1
gh release create vX.Y.Z-dn.1 --title "vX.Y.Z-dn.1" --notes "…"
```

Other DartNative work goes the same way: a feature branch from `dartnative`
and a PR into `dartnative`. Changes meant for upstream branch from `main`.

`tool/dartnative_check.sh` fails if upstream added a Flutter-only import or
export to `lib/` or `hook/`. It then analyzes the package (`lib/` and
`hook/`) and `dn_example` against the DartNative SDK, and
with `--build` also builds the example for the iOS simulator and Android. After
that, run `dn_example` on a device and press each button. The fork does not
run upstream's `test/`: some of its Dart tests need `flutter_test`, which the
fork drops.

## Hot restart

Keeping callbacks safe needs no fork-specific code. Upstream already sends
every native call into Dart through a gate (`src/dart_callback_gate.h`). A `NativeFinalizer`
retires that gate when the isolate shuts down. With no FlutterEngine id, it
retires every callback. The Dart VM runs native finalizers before it deletes
the isolate's FFI callbacks (`Isolate::Shutdown`), so a voice that ends after
the restart finds the gate closed instead of calling a dead pointer. After a
restart, `init()` finds the native engine still running and resets it. The
one fork-specific piece is `compute` (see Known DartNative issues).

Realtime stream feeders (`startFloat32Feeder`/`startInt16Feeder`) keep a
small native buffer until their `dispose()`, on their own isolate by default
or on the main one with `useIsolate: false`. A hot restart with one running
drops that buffer without freeing it, so dispose feeders before restarting
when you can.

To check it after a sync, run `dn_example` with `dn run`:

1. Press **Init**, then **MP3 asset** or **Opus asset**.
2. Press **Callback stress**. Native code then keeps calling Dart for 8 s.
3. Press capital `R` during those 8 s.
4. Repeat a few times. The app must not abort with `Callback invoked after it
   has been deleted`, and every restart must finish.

## Known DartNative issues

- **Android builds fail on JDK 25 with apps from `dn create`** (checked on
  DartNative 1.8.0). Its template uses Gradle 8.14, which can't run on
  JDK 25. `dn` uses `dn config --jdk-dir` if set, else Android Studio's
  bundled JDK (25 in current releases), else `JAVA_HOME`, then `PATH`. The
  Gradle error is just the JDK version, e.g. `25.0.4`. Point
  `dn config --jdk-dir` at JDK 17 or 21, or move the app to AGP 9 as
  `dn_example` does, with Flutter 3.50's defaults: AGP 9.3.1, Gradle 9.5.0
  and Kotlin 2.4.20 (AGP 9.3 needs Gradle 9.5). Apply the changes in its
  four Gradle files to yours rather than copying the files, which would
  replace your app ID and signing: `settings.gradle.kts`, the wrapper's
  `gradle-wrapper.properties`, `gradle.properties` and
  `app/build.gradle.kts`. The app file keeps `id("kotlin-android")` and
  moves `jvmTarget` into a top-level `kotlin { compilerOptions { … } }`
  block. `gradle.properties` has three opt-outs because DartNative's Gradle
  plugin predates AGP 9; without `android.sourceset.disallowProvider=false`
  it fails with `You cannot add Provider instances to the Android SourceSet
  API`. AGP 10 drops the opt-outs, so moving to it needs a DartNative
  plugin that supports AGP 9's new DSL.
- **Android rebuilds fail with `mergeDebugJniLibFolders uses this output of
  task compileFlutterBuildDebug`** on affected DartNative versions
  ([DartNative#83](https://github.com/DartNative/dartnative/issues/83), fixed
  in 1.5.1). The first build after `dn clean` works, later ones fail, with any
  package whose native code comes from a build hook. Apps on an affected
  version need the workaround at the bottom of
  `dn_example/android/app/build.gradle.kts`; it is harmless on newer ones.
- **Hot restart could hang after DartNative's `compute`** on DartNative 1.5.0
  ([DartNative#82](https://github.com/DartNative/dartnative/issues/82), fixed
  in 1.5.1). Its `compute` runs on a background pool whose isolates stay
  alive between calls, and `dn` killing them on hot restart often left the
  restart unfinished. `flutter_compat.dart` defines `compute` with
  `Isolate.run`, as Flutter does, so its isolates exit when the work is done
  and the fork does not depend on that pool. Keep it that way unless there is
  a reason to switch.
- **`dn config --license-key` must run inside the app folder** (`dn_example/`),
  not the repository root.
