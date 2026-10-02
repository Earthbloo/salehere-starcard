# Star Card — Android

Kotlin + Jetpack Compose port of `../StarCard` (the iOS SwiftUI prototype): the mock Sale Here shell,
the Star flow (register wizard · Star Profile · accept · KYC · Lab), the card gallery, template picker,
card editor, export/share, profile intake, and all 79 widgets.

`PORTING.md` is the contract the port was written against. Read it before changing anything shared.

## Build & run

Uses the JDK bundled with Android Studio and the SDK at `~/Library/Android/sdk`.

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
./gradlew :app:assembleDebug
~/Library/Android/sdk/platform-tools/adb install -r app/build/outputs/apk/debug/app-debug.apk
~/Library/Android/sdk/platform-tools/adb shell am start -n co.salehere.starcard/.MainActivity
```

Emulator: AVD `starcard` (Android 16 / API 36, arm64). It needs **≥ 7.4 GB free disk** to create its userdata.

```bash
~/Library/Android/sdk/emulator/emulator -avd starcard -no-snapshot-save -no-boot-anim
```

Toolchain: AGP 9.4.1 · Kotlin 2.4.20 · Gradle 9.8.0 · compileSdk 37 · minSdk 26 · Compose BOM 2026.09.00.

## Layout

| Folder | From iOS |
|---|---|
| `model/` | `Model/*` — StarFlow, Profile, Intake, Portfolio, CardLibrary/Store, PhotoStore, WidgetModel… |
| `theme/` | `Theme/*` + Phosphor icons (`Ph`), SF Symbol → Phosphor map (`Symbols.kt`), colour tools |
| `components/` | `Components/*` — Motion (page scrub), Glass, Shapes |
| `layout/` | `Layout/CardLayout.swift` |
| `ui/` | `Views/*` — CardScreen, CardGallery, TemplatePicker, sheets, `editor/`, `export/`, `profile/`, `salehere/`, `widgets/` |

`ui/widgets/WidgetKit.kt` holds the helpers that several widget files share (Ed*, Cutout*, seals, QR, FlowLayout…).

## Differences from iOS (by design)

- **Liquid Glass** is drawn as a frosted translucent panel. Android has no system glass material.
- **Automatic background removal** (Apple Vision) is a stub. Opaque photos fall back to each poster's framed layout.
  A PNG that already has a transparent background still stands on the card as a cutout.
- The **App Clip** is replaced by a deep link (`https://star.salehere.co.th/star/<slug>`).
- Text uses a fixed `fontScale = 1`, so the card looks identical on every phone.
