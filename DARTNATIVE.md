# DartNative fork

This repository is a fork of [alnitak/flutter_soloud](https://github.com/alnitak/flutter_soloud)
that runs on [DartNative](https://dartnative.com) (iOS and Android). DartNative
has no Flutter framework, only a stub `package:flutter`, so the fork carries a
small patch on top of upstream. This file lists that patch and how to keep it
current.

## The patch

Everything else is upstream, untouched.

| File | Change | On a merge conflict |
|---|---|---|
| `lib/src/dartnative/flutter_compat.dart` | New. Provides the Flutter names the package uses (`kIsWeb`, `defaultTargetPlatform`, `debugPrint`, `compute`, `rootBundle`, typed data, `meta`) on top of `package:dartnative`. `compute` is `Isolate.run`, as in Flutter, not DartNative's (see below). | Fork-only, no conflicts. Add to it when upstream starts using another Flutter API. |
| `lib/src/dartnative/path_provider_compat.dart` | New. `getTemporaryDirectory()` over `dartnative_path_provider`. | Fork-only. |
| `soloud.dart`, `filters/filters.dart`, `filters/parametric_eq.dart`, `utils/loader_base.dart`, `utils/loader_io.dart`, `utils/loader_web.dart` | `package:flutter/*` imports (and `path_provider` in `loader_io.dart`) replaced by the compat imports. Nothing else. | Take upstream's file, then swap the imports again. |
| `bindings/darwin_engine_lifecycle.dart` | Rewritten as a stub that is never supported (no FlutterEngine, no MethodChannel). | Keep ours. If upstream changes the class's public API, mirror it in the stub. |
| `bindings/bindings_player_ffi.dart` | No `dart:ui`; `currentEngineId` always returns `noEngineId`. | Take upstream's file, then remove `dart:ui` and restore the one-line getter. |
| `pubspec.yaml` | Drops `flutter`, `flutter_test`, `path_provider`, `plugin_platform_interface` and the `flutter:` plugin/assets block; adds `dartnative`, `dartnative_path_provider`. | Take upstream's version and new dependencies, keep ours for everything listed here. |
| `dn_example/`, `DARTNATIVE.md`, `tool/dartnative_check.sh` | Fork-only. | — |

Rules that keep the patch small:

- **Don't delete upstream files** (web, desktop, the Flutter `example/`,
  `android/`, `ios/`). DartNative never builds them, and deleting them turns
  every upstream edit to them into a modify/delete conflict.
- **Don't rename the package in the source.** Every file imports
  `package:flutter_soloud/…`, so a rename would conflict on every sync. If it
  ships on dartpub.dev under another name, rename at publish time.
- **Route new Flutter APIs through `flutter_compat.dart`** rather than editing
  upstream code.

## Syncing with upstream

Two branches:

- **`main`** mirrors upstream exactly. Never commit to it; keep it current with
  GitHub's "Sync fork" button or `gh repo sync hectorAguero/dartnative_soloud`.
- **`dartnative`** is the DartNative version: the default branch, and what
  gets published. `git diff main dartnative` is always the whole patch.

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

Other DartNative work goes the same way: a feature branch from `dartnative`
and a PR into `dartnative`. Changes meant for upstream branch from `main`.

`tool/dartnative_check.sh` fails if upstream added a Flutter-only import. It
then analyzes the package and `dn_example` against the DartNative SDK, and
with `--build` also builds the example for the iOS simulator and Android. After
that, run `dn_example` on a device and press each button.

## Hot restart

Hot restart needs no fork-specific code. Upstream already sends every native
call into Dart through a gate (`src/dart_callback_gate.h`). A `NativeFinalizer`
retires that gate when the isolate shuts down. With no FlutterEngine id, it
retires every callback. The Dart VM runs native finalizers before it deletes
the isolate's FFI callbacks (`Isolate::Shutdown`), so a voice that ends after
the restart finds the gate closed instead of calling a dead pointer. After a
restart, `init()` finds the native engine still running and resets it.

To check it after a sync, run `dn_example` with `dn run`:

1. Press **Init**, then **MP3 asset** or **Opus asset**.
2. Press **Callback stress**. Native code then keeps calling Dart for 8 s.
3. Press capital `R` during those 8 s.
4. Repeat a few times. The app must not abort with `Callback invoked after it
   has been deleted`, and every restart must finish.

## Known DartNative issues

- **Android rebuilds fail with `mergeDebugJniLibFolders uses this output of
  task compileFlutterBuildDebug`.** The first build after `dn clean` works,
  later ones fail. This happens with any package whose native code comes
  from a build hook. `dn_example/android/app/build.gradle.kts` has the
  workaround at the bottom; apps that use this package need the same lines
  until DartNative fixes it.
- **Hot restart can hang after DartNative's `compute`.** Its `compute` runs on
  a background pool (`runInBackground` and its workers). Those isolates stay
  alive between calls, and `dn` kills them on hot restart. About one restart
  in five then never finishes: `dn` prints "Performing hot restart..." and the
  old session keeps running. This reproduces with a plain `compute` call and no
  SoLoud code. `flutter_compat.dart` therefore defines `compute` with
  `Isolate.run`, so its isolates exit when the work is done. Don't export
  DartNative's `compute` again until this is fixed.
- **`dn config --license-key` must run inside the app folder** (`dn_example/`),
  not the repository root.
