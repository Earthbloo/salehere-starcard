# StarCard Android — porting contract

Android port of `../StarCard` (iOS 26 SwiftUI prototype, ~38k lines) to **Kotlin + Jetpack Compose**.
This file is the contract every porter follows so that files written in parallel compile together.
Read it fully before writing a line.

## 0. Ground rules

1. **1:1 port.** One Kotlin file per Swift file, same base name (`CardTheme.swift` → `theme/CardTheme.kt`).
   Same type names, same property/function names (camelCase as in Swift), same enum case names, same
   default values, same Thai strings. Keep the design decisions; port the *behaviour*, not the SwiftUI API.
2. **Keep the Thai doc comments** — shorten to the first 1–3 lines of each comment block (the "why").
   Drop SwiftUI-mechanics comments that no longer apply.
3. **Never edit a file owned by another porter.** If you need a helper that does not exist, put it in
   your own area's file (e.g. `ui/widgets/GalleryHelpers.kt`) with `internal` visibility and list it in
   your final report. Do not create a second `Locals.kt`, `Typography.kt`, `Motion.kt`, etc.
4. **Compile-clean is not required for your files alone** (other areas may still be missing), but every
   reference to another area must use the *exact names* listed in this contract or in the Swift source.
   Guess nothing: `grep` the Swift file for the real name.
5. No new architecture (no ViewModels, no Hilt, no Navigation library). Screens switch with state +
   `AnimatedContent`/`AnimatedVisibility`, exactly like the iOS shell does with `if let screen`.
6. `minSdk 26`, `compileSdk 37`, Compose BOM 2026.09.00, Kotlin 2.4.20, material3 only for `Text`,
   `Icon`, `LocalContentColor`, `Surface`-less. We do **not** use Material theming, buttons, or colors —
   every visual is drawn with foundation + our own tokens, like the iOS app.

## 1. Package layout (mirrors the iOS folders)

```
co.salehere.starcard
├── StarCardApp.kt, MainActivity.kt, ContentView.kt     ← StarCardApp.swift, ContentView.swift
├── model/        ← Model/*.swift          (WidgetModel, WidgetContent, CardTheme? no → theme/, CardStore, CardLibrary,
│                                           CardFormat, CardPage, CardTemplate, ClipInvocation, Cutout, EditHistory,
│                                           Intake, MockData, PhotoLift, PhotoStore, Portfolio, Profile, StarCampaign,
│                                           StarFlow, SubjectLift, Fmt)
├── theme/        ← Theme/*.swift          (CardTheme, ColorDuo, Legibility, Marble, SHStyle, Signature, TextStyle,
│                                           Typography) + Ink.kt, ColorTools.kt, Ph.kt, Symbols.kt (foundation, done)
├── layout/       ← Layout/CardLayout.swift
├── components/   ← Components/*.swift     (Glass, Motion (done), Shapes)
└── ui/           ← Views/
    ├── Locals.kt, Haptics.kt (done)
    ├── CardScreen.kt, CardGallery.kt, CardPreviews.kt, TemplatePicker.kt, ContactSheet.kt, VerifySheet.kt, SafariSheet.kt
    ├── editor/    ← Views/Editor/*        (ControlSheet, EditableText, EditorDock, PressDragCatcher, TextTools, WidgetGallery)
    ├── export/    ← Views/Export/*
    ├── profile/   ← Views/Profile/*  (+ profile/sections/*)
    ├── salehere/  ← Views/SaleHere/* (+ salehere/starflow/*)
    └── widgets/   ← Views/Widgets/*
```

Package name = folder (`co.salehere.starcard.ui.widgets`). Import freely across packages.

## 2. Swift → Kotlin type mapping

| Swift | Kotlin |
|---|---|
| `enum X: String, CaseIterable` | `enum class X(val raw: String) { a("a"), …; companion object { fun from(raw: String?): X? = entries.firstOrNull { it.raw == raw } } }` — `allCases` → `entries`, `X(rawValue:)` → `X.from(...)`, `.rawValue` → `.raw`, `var name`/`label`/`title` computed props → `val name get() = when(this){…}` |
| `enum X { case a(Assoc) }` | `sealed class X { data class A(val v: Assoc) : X(); object B : X() }` — keep case names lowercase where possible via `sealed interface`; when Swift uses `.data(k)` write `StarTopic.Data(k)` |
| `struct` (value type) | `data class` with `val` for `let`, `var` for `var`. **Swift `mutating func f()` → `fun f(): T` returning a copy** (same name). Callers write `theme = theme.setDuo(d)` |
| `@Observable final class` singleton | `class X private constructor() { companion object { val shared: X by lazy { X() } } }` and every stored property that views read is `var p by mutableStateOf(v)`. Keep the name `shared` (or `me` for `Profile.me`). `didSet { save() }` → a private `setter` that calls `save()` |
| `@Environment(PhotoStore.self)` | `LocalPhotoStore.current` (declared in `PhotoStore.kt` as **nullable**: `val LocalPhotoStore = staticCompositionLocalOf<PhotoStore?> { null }`; readers do `LocalPhotoStore.current ?: return` or `!!`) · `LocalStarFlow = compositionLocalOf { StarFlow.shared }` (`StarFlow.kt`) · `LocalClipInvocation = staticCompositionLocalOf { ClipInvocation() }` (`ClipInvocation.kt`) |
| `@Environment(\.key)` | the CompositionLocal listed in §5 |
| `CGFloat`, `Double` (geometry) | `Float` — design units are pt == dp. Use `Float` for x/y/w/h/sizes/radii. Keep `Double` where Swift used `Double` for ratios (luminance, opacity, hue, brightness) |
| `CGSize` / `CGRect` / `CGPoint` | `androidx.compose.ui.geometry.Size` / `Rect` / `Offset` |
| `UUID` | `java.util.UUID` (`UUID.randomUUID()`, `UUID.fromString`) |
| `Color(red:green:blue:)` | `rgb(r, g, b)` (Doubles) or `Color(0xFFRRGGBB)`; `Color(hue:saturation:brightness:)` → `hsb(h, s, b)`; `.opacity(x)` → `.opacity(x)` (**multiplies** the existing alpha exactly like SwiftUI — port literally, never compensate); `Color.white.opacity(0.5)` → `Color.White.opacity(0.5)`; `.clear` → `Color.Transparent`; `.mixed(with:by:)` → `.mixed(c, t)`; `Color.hex(0x..)` → `Color.hex(0x..)` |
| `Font.sh(13, .bold)` | `sh(13f, SHFont.bold)` → `TextStyle`; pass as `Text(..., style = sh(13f, SHFont.bold))`. `Font.Weight` → `SHFont.black/heavy/bold/semibold/medium/regular/light` (= `FontWeight`) |
| `.font(.system(size:weight:design:))` | `systemFont(size, weight, serif = …)` |
| `Text("x").foregroundStyle(c)` | `Text("x", style = …, color = c)`; container-level `.foregroundStyle(c)` → `Tinted(c) { … }` (sets `LocalContentColor`) |
| `Image(systemName: "x")` | `SFSymbol("x", size = …)` (theme/Symbols.kt); `PIcon(.check, size:)` → `PIcon(Ph.check, size = …)`; `Ph.check.bold` → `PIcon(Ph.check, weight = PhWeight.bold)` |
| `Image("asset-name")` | `Image(painterResource(SHIcon.xxx))` (all asset ids live in `SHIcon`, theme/Typography.kt); template rendering → `SymbolIcon(res, size, tint)`; original colours → `BrandIcon(res, size)` |
| `UIImage` | `android.graphics.Bitmap`; draw with `Image(bitmap.asImageBitmap(), …)` |
| `URL` | `String` (keep `url` as `String`; open with `LocalOpenURL.current(url)`) |
| `Date` | `Long` epoch millis (`System.currentTimeMillis()`) |
| `UserDefaults.standard` | `AppContext.prefs` (SharedPreferences) + JSON via kotlinx.serialization (`Json { ignoreUnknownKeys = true; encodeDefaults = true }`) |
| Documents directory | `AppContext.filesDir` |
| `Codable` DTO | `@Serializable data class` (optional fields default `null`) |
| `Haptics.impact(.light)` | `Haptics.impact(Haptics.Style.light)` / `Haptics.light()` |
| `Task { … }` / `async` | `LaunchedEffect` / `rememberCoroutineScope().launch` / `withContext(Dispatchers.IO)` |
| `DispatchQueue.main.asyncAfter` | `scope.launch { delay(ms); … }` |
| `Fmt.compact(n)` | `Fmt.compact(n)` (model/Fmt.kt) |

## 3. SwiftUI → Compose view mapping

| SwiftUI | Compose |
|---|---|
| `struct Foo: View { let a; var b = 1; var body }` | `@Composable fun Foo(a: A, b: Int = 1, modifier: Modifier = Modifier)` — **always take a trailing `modifier` param** |
| `ZStack` / `VStack(spacing)` / `HStack(spacing)` | `Box` / `Column(verticalArrangement = Arrangement.spacedBy(x.dp))` / `Row(horizontalArrangement = …)` |
| `Spacer()` in stack | `Spacer(Modifier.weight(1f))`; `Spacer(minLength: 0)` → `Spacer(Modifier.weight(1f, fill = false))`; fixed `Spacer().frame(width: 8)` → `Spacer(Modifier.width(8.dp))` |
| `ForEach(items) { }` | `items.forEach { }` inside the layout (or `LazyRow`/`LazyColumn` for long scrollers) |
| `.frame(width:height:)` | `Modifier.size(w.dp, h.dp)` / `.width()` / `.height()`; `.frame(maxWidth: .infinity)` → `.fillMaxWidth()`; alignment via `Box(contentAlignment)` or `.wrapContentSize(align)` |
| `.padding(x)` / `.padding(.horizontal, x)` | `.padding(x.dp)` / `.padding(horizontal = x.dp)` |
| `.background(shape.fill(c))` | `.background(c, shape)`; `.background(gradient)` → `.background(Brush.linearGradient(...), shape)` |
| `.overlay(shape.strokeBorder(c, lineWidth))` | `.border(lineWidth.dp, c, shape)` |
| `.overlay { view }` | wrap in `Box { content; overlayView }` |
| `.clipShape(shape)` / `.clipped()` | `.clip(shape)` / `.clipToBounds()` |
| `RoundedRectangle(cornerRadius: r, style: .continuous)` | `RoundedCornerShape(r.dp)` (continuous corners ≈ same); `Capsule()` → `CircleShape` (for pills) ; `Circle()` → `CircleShape` |
| `.opacity(a)` | `.alpha(a)` |
| `.offset(x:y:)` | `.offset(x.dp, y.dp)` (layout) or `graphicsLayer { translationX = x * density }` (visual only) |
| `.scaleEffect(s, anchor:)` | `graphicsLayer { scaleX = s; scaleY = s; transformOrigin = TransformOrigin(ax, ay) }` |
| `.rotationEffect(.degrees(a))` | `graphicsLayer { rotationZ = a }` |
| `.rotation3DEffect(.degrees(a), axis: (x:0,y:1,z:0), perspective:)` | `graphicsLayer { rotationY = a; cameraDistance = 8f * density }` |
| `.blur(radius:)` | `Modifier.blur(r.dp)` (no-op < API 31, fine) |
| `.shadow(color:radius:y:)` | `Modifier.shadow(elevation = r.dp, shape, ambientColor = c, spotColor = c)` for solid panels; for glows use `drawBehind { drawRoundRect(brush = radialGradient(...)) }` |
| `LinearGradient(colors:startPoint:endPoint:)` | `Brush.linearGradient(colors, start = Offset, end = Offset)` — top→bottom = `Brush.verticalGradient(colors)`; leading→trailing = `Brush.horizontalGradient` |
| `RadialGradient` | `Brush.radialGradient(colors, center, radius)` |
| `Canvas { ctx, size in … }` | `Canvas(modifier) { … }` with `drawPath/drawRect/drawCircle`; `Path` → `androidx.compose.ui.graphics.Path` |
| `Shape` (custom) | `object ArchShape : Shape { override fun createOutline(...) = Outline.Generic(path) }` (see components/Shapes.kt) |
| `.mask { view }` | `graphicsLayer(compositingStrategy = Offscreen).drawWithContent { drawContent(); draw mask with blendMode = DstIn }` |
| `GeometryReader { geo in }` | `BoxWithConstraints { maxWidth/maxHeight }` or `Modifier.onSizeChanged` |
| `.lineLimit(n)` / `.truncationMode(.tail)` | `maxLines = n, overflow = TextOverflow.Ellipsis` |
| `.minimumScaleFactor(k)` | `Text(..., autoSize = TextAutoSize.StepBased(minFontSize = (size*k).sp, maxFontSize = size.sp, stepSize = 0.5.sp))` |
| `.fixedSize()` | `Modifier.wrapContentSize()` + `softWrap = false` |
| `.multilineTextAlignment(.center)` | `textAlign = TextAlign.Center` |
| `.tracking(x)` / `.kerning` | `style.copy(letterSpacing = x.sp)` |
| `.lineSpacing(x)` | `style.copy(lineHeight = (size + x).sp)` |
| `.textCase(.uppercase)` | `text.uppercase()` |
| `.redacted(reason: .placeholder)` | `Modifier.redacted(on)` (components/Glass.kt helper: draws a rounded bar over the content) |
| `.allowsHitTesting(false)` | wrap with `Box(Modifier.pointerInput(Unit) {}).also{}` → simplest: nothing (widget content never has handlers) |
| `withAnimation(Motion.snap) { x = y }` | `x = y` where `x` is read through `animateFloatAsState(target, Motion.snap.float)` / `Animatable.animateTo(y, Motion.snap.float)`; for enter/exit of whole views use `AnimatedVisibility(visible, enter = fadeIn(Motion.page.float) + slideInHorizontally(...))` |
| `.transition(.move(edge: .trailing))` | `slideInHorizontally { it } / slideOutHorizontally { it }` |
| `.animation(Motion.snap, value: v)` | `animateXAsState(v, Motion.snap.float)` |
| `TimelineView(.animation)` | `rememberSeconds()` (components/Motion.kt) → recompose per frame |
| `@State` | `var x by remember { mutableStateOf(v) }`; `@Binding` → pass value + `onChange: (T) -> Unit` |
| `.onAppear` / `.task` | `LaunchedEffect(Unit)` |
| `.onChange(of: v) { }` | `LaunchedEffect(v) { }` |
| `Button { } label: { }` | `Box(Modifier.clickable(interactionSource, indication = null) { })` — **no ripple** anywhere (iOS has none) |
| `.buttonStyle(.plain)` | `indication = null` |
| `ScrollView(.horizontal)` | `Row(Modifier.horizontalScroll(rememberScrollState()))` |
| `sheet` / `fullScreenCover` | our own overlay: `if (shown) Box(Modifier.fillMaxSize()) { scrim; content }` with `AnimatedVisibility` (no `ModalBottomSheet`) |
| `DragGesture` | `pointerInput(Unit) { detectDragGestures(...) }`; `MagnifyGesture` → `detectTransformGestures`; long-press-drag → `detectDragGesturesAfterLongPress` |
| `PhotosPicker` | `rememberLauncherForActivityResult(ActivityResultContracts.PickMultipleVisualMedia(n))` → decode with `ImageDecoder` |
| `.glassEffect(...)` (Liquid Glass) | `GlassPanel(...)` from components/Glass.kt — a frosted veil (white/black translucent fill + hairline rim highlight). No real backdrop blur. |
| `Anchor<CGRect>` preferences (`photoSlot`, `linkSlot`, `editableText`) | `Modifier.onGloballyPositioned { it.boundsInRoot() }` reporting into the registries described in §6 |
| `UIViewRepresentable` | `AndroidView` only if unavoidable; prefer pure Compose |

**Fonts scale:** the root `ContentView` overrides `LocalDensity` with `fontScale = 1f`, so `x.sp == x.dp`.
Never compensate for font scale yourself.

**Design units:** widgets are laid out in design pt inside a container that the card scales
(`graphicsLayer { scale }`), so inside widget code `12` pt = `12.dp` — write `.dp`, never `.px`.

## 4. Foundation already written (use, do not rewrite)

| File | Provides |
|---|---|
| `theme/SHStyle.kt` | `SHColor.red/ink/page/stroke/…` |
| `theme/ColorTools.kt` | `hsb()`, `rgb()`, `grey()`, `Color.hex()`, `Color.opacity()`, `Color.mixed()`, `Color.toHSB()`, `Color.onLightSurface()`, `Color.toHexString()`, `Color.approx()` |
| `theme/Legibility.kt` | `Legibility.{body,large,photo,linear,encoded,ratio,target,composite,alpha}`, `RGB`, `InkGround`, `Color.legible()`, `PhotoVeil` |
| `theme/Ink.kt` | `CardInk`, `InkStyle` (`text(l)`, `ghost`, `line`, `fill`, `lift`, `liftRadius`, `covered`, `coveredByInk`, `isLight`, `base`, `ground`), `LocalCardInk` |
| `theme/Typography.kt` | `SHFont` (family, weights), `sh(size, weight)`, `systemFont()`, `statNumber()`, `display()`, `serifItalic()`, `SHIcon.*` (all drawable ids), `BrandIcon`, `SymbolIcon`, `SaleHereMark`, `Tinted` |
| `theme/Ph.kt` | `Ph` enum (69 icons, same names as iOS), `PhWeight`, `PIcon(icon, size, weight, tint)` |
| `theme/Symbols.kt` | `SFSymbol(name, size, tint)` — SF Symbol name → Phosphor |
| `components/Motion.kt` | `Motion.{snap,flow,lift,page,settle}` (`SpringToken`, `.float` spec), `Motion.stagger`, `MotionFX`, `EntranceStyle`, `PageScrub`, `LocalPageScrub`, `Scrub.{dir,t,ease,lead,fade,mix,cell}`, `Modifier.scrubAperture/scrubVeil/scrubDolly/scrubLouver/scrubSlide/pageChoreo/pressTilt`, `ScrubDigits`, `ScrubRunner`, `rememberSeconds()`, `Float.pt` |
| `ui/Locals.kt` | `LocalWidgetID`, `LocalCardAccent`, `LocalTextEditMode`, `LocalSlotTilt`, `LocalGhostData`, `LocalSampleData`, `LocalPreviewStatic`, `LocalPageContentWidth`, `LocalCanvasTyping`, `LocalOpenURL`, `LocalDismiss` |
| `ui/Haptics.kt` | `Haptics.impact(style)`, `Haptics.light()/medium()/rigid()` |
| `model/Fmt.kt` | `Fmt.compact/baht/money/pct/f` |
| `StarCardApp.kt` | `AppContext.app / prefs / filesDir` |

`WidgetKind.entranceStyle` (in Motion.swift) must be ported **inside `model/WidgetModel.kt`** as
`val WidgetKind.entranceStyle: EntranceStyle` (extension) by the WidgetModel porter.

## 5. CompositionLocals — where each one lives

| iOS `\.key` | Kotlin | Declared in |
|---|---|---|
| `cardInk` | `LocalCardInk` | theme/Ink.kt (done) |
| `cardAccent` | `LocalCardAccent` | ui/Locals.kt (done) |
| `widgetID` | `LocalWidgetID` | ui/Locals.kt (done) |
| `widgetTextStyle` | `LocalWidgetTextStyle` | theme/TextStyle.kt |
| `widgetSurface`, `widgetPattern`, `widgetEmboss`, `widgetEmbossBlind`, `widgetLiftsPhoto`, `widgetBorder`, `popSkin` | `LocalWidgetSurface`, `LocalWidgetPattern`, `LocalWidgetEmboss`, `LocalWidgetEmbossBlind`, `LocalWidgetLiftsPhoto`, `LocalWidgetBorder`, `LocalPopSkin` | model/WidgetModel.kt |
| `pageScrub` | `LocalPageScrub` | components/Motion.kt (done) |
| `textEditMode`, `slotTilt`, `ghostData`, `sampleData`, `previewStatic`, `pageContentWidth`, `canvasTyping` | `Local…` | ui/Locals.kt (done) |
| `wizardHeading` | `LocalWizardHeading` | ui/profile/ProfileFlow.kt |
| `PhotoStore.self` | `LocalPhotoStore` | model/PhotoStore.kt |
| `StarFlow.self` | `LocalStarFlow` | model/StarFlow.kt |
| `ClipInvocation.self` | `LocalClipInvocation` | model/ClipInvocation.kt |
| `openURL` / `dismiss` | `LocalOpenURL` / `LocalDismiss` | ui/Locals.kt (done) |

## 6. Slot registries (replace `anchorPreference`)

Widgets are non-interactive; the card layer decides what a tap means. iOS used preference keys to send
frames up. On Android use one registry object per card page, passed through locals declared in
`ui/editor/EditableText.kt` (owner: editor porter):

```kotlin
// ui/editor/EditableText.kt (owner: porter E) — exact API, everyone else only calls it
data class PhotoSlotRect(val index: Int, val rect: Rect)
data class LinkSlotRect(val url: String, val rect: Rect)
data class TextSlotRect(val id: TextSlotID, val rect: Rect, val style: TextSlotStyle)

class SlotRegistry {                       // one per CardScreen page; plain class, NOT observable
    var scale = 1f                         // page design units → root px, set by CardScreen every layout
    var origin = Offset.Zero               // root px position of the page's top-left
    val text = mutableMapOf<UUID, MutableList<TextSlotRect>>()
    val links = mutableMapOf<UUID, MutableList<LinkSlotRect>>()
    val photos = mutableMapOf<UUID, MutableList<PhotoSlotRect>>()
    fun toPage(rootRect: Rect): Rect       // (rootRect - origin) / scale
    fun reportText(widget: UUID, slot: TextSlotRect)    // replaces the entry with the same id
    fun reportLink(widget: UUID, slot: LinkSlotRect)    // replaces the entry with the same url+rect
    fun reportPhoto(widget: UUID, slot: PhotoSlotRect)  // replaces the entry with the same index
    fun hitText(point: Offset, widget: UUID): TextSlotRect?   // last match wins, 6pt slop
    fun hitLink(point: Offset, widget: UUID): String?
}
val LocalSlotRegistry = staticCompositionLocalOf<SlotRegistry?> { null }
```
`Modifier.editableText(field, index, widget, preset, hint, style)` (EditableText.kt),
`Modifier.linkSlot(url: String?)` (ui/widgets/LinkSlot.kt), `Modifier.photoSlot(index)` (model/PhotoStore.kt)
all do: `onGloballyPositioned { val reg = LocalSlotRegistry.current; val id = LocalWidgetID.current;
if (reg != null && id != null) reg.reportX(id, X(..., reg.toPage(it.boundsInRoot()))) }` (read the locals in
a `composed {}` / `@Composable Modifier` function). Rects are stored in **page design coordinates**.

Other cross-area facts:
- `Ph.package` is a Kotlin keyword → write `` Ph.`package` ``.
- `VerifiedFacts` (from Views/Widgets/VerifiedSealWidget.swift) is ported by porter A into `theme/VerifiedFacts.kt`
  (object with the same static members: `sheetURL`, `labForce`, …). The seal widget porter must not redefine it.
- `ImageCache` (WidgetShared.swift) is our own `LruCache<String, Bitmap>` + `suspend fun load(url)` over
  `java.net.URL` on `Dispatchers.IO` (no Coil) so that `ImageCache.shared.cached(url)` stays synchronous.
- `WidgetBody` (WidgetShared.kt, porter E) dispatches to every widget composable by its Swift name with the
  Swift init parameters (`ArtPortrait(theme, size)`, `ArtPolaroid(theme)` …). Porter E also writes
  `ui/widgets/WidgetStubs.kt` with a placeholder for each of those names so wave 1 compiles; wave 2 deletes it.

## 7. Persistence keys (must match iOS so the shape is the same)

`starflow.v1`, `starcard.library.v1`, `starcard.library.published`, `starcard.profile.v1`,
`starcard.draft.v2.<format>`, `starcard.draft.enabled` — all in `AppContext.prefs` as JSON strings.
Photos: `filesDir/starcard-photos/…`, `starcard-backdrop.jpg`, `starcard-profile.jpg`, `starcard-bookbank.jpg`.

## 8. Things that have no Android equivalent — do this

- **Liquid Glass** → `GlassPanel` (frosted translucent panel). Do not try `RenderEffect` blur.
- **Apple Vision subject lift** (`PhotoLift`, `SubjectLift`) → stub that returns `null`/"not available";
  keep the API so widgets compile. (ML Kit can be added later.)
- **CoreImage halftone** (`PhotoStore.bake`) → simple dot-screen drawn in Kotlin over a downscaled bitmap.
- **`ImageRenderer` export** (`CardA4Export`) → `Picture`/`Canvas` via `graphicsLayer.toImageBitmap()`
  (Compose 1.7+: `rememberGraphicsLayer()` + `layer.toImageBitmap()`), share with `Intent.ACTION_SEND`.
- **`UITextView` typing on canvas** (`CanvasTextField`) → `BasicTextField` with our `TextStyle`.
- **App Clip** (`AppRuntime.isClip`) → always `false`; `ClipInvocation` parses `Intent.data`.
- **PDF icons** were rasterised to `drawable-nodpi` PNGs — `SymbolIcon` tints them fine.
- **Fonts `Didot-Italic`, `SukhumvitSet`, `Thonburi`, `Krungthep`** don't exist → `CardFont` maps them to
  `FontFamily.Serif` italic / `SHFont.mitr` / system sans; keep the enum cases and Thai names.

## 9. Ownership matrix (wave 1 — models & theme)

| Porter | Files (Swift → Kotlin) |
|---|---|
| A · theme | Theme/CardTheme.swift (rest: `Palette`, `CornerStyle`, `BackdropStyle`, `BackdropEffect`, `CardTheme`, `CardBackdrop`, `BackdropStripes/Diamonds/Grid`, `PlatePatternLayer`), Theme/ColorDuo.swift, Theme/Marble.swift, Theme/Signature.swift, Theme/TextStyle.swift |
| B · model core | Model/WidgetModel.swift (+ `WidgetKind.entranceStyle` from Motion.swift), Model/WidgetContent.swift, Model/CardFormat.swift, Model/CardPage.swift, Model/CardTemplate.swift, Model/CardStore.swift, Model/CardLibrary.swift, Model/EditHistory.swift, Layout/CardLayout.swift |
| C · model data | Model/Profile.swift, Model/Intake.swift, Model/Portfolio.swift, Model/MockData.swift (all types + `Mock` + `DebugFlags`; `Fmt` is done), Model/StarCampaign.swift, Model/StarFlow.swift, Model/ClipInvocation.swift |
| D · photos | Model/PhotoStore.swift (`PhotoLib`, `ImageCache`, `RemoteLogo`, `RemotePhoto`, `PhotoFit`, `PhotoStore`, `LocalPhotoStore`, `WidgetPhoto`, `PhotoSlotButton`, `BackgroundPickButton`, `PhotoUploadButton`, `PhotoFitSurface`, `PhotoFitCatcher`, `Bitmap.dominantTone`), Model/Cutout.swift, Model/PhotoLift.swift, Model/SubjectLift.swift, Theme/Legibility.swift `PhotoLuma` → model/PhotoLuma.kt |

Wave 2 (after wave 1 compiles): components (Glass, Shapes, WidgetChrome, WidgetShared, LinkSlot, EditableText),
widgets (6 groups), shell + StarFlow, editor, gallery/templates/export, profile intake.

## 10. Report format (end of your task)

List: files written · public names that differ from Swift (and why) · helpers you had to invent ·
anything you could not port (with the Swift line). Keep it under 40 lines.

## 11. Text slots API (how widgets render editable text)

iOS: `Text(Profile.me.name).editableText(.name, style)` — the modifier injects font/colour and registers the frame.
Compose modifiers cannot style a `Text`, so the slot **is** the text composable (owner: porter E, `ui/editor/EditableText.kt`):

```kotlin
@Composable
fun EditableText(
    field: ProfileField, index: Int? = null, widget: UUID? = null, preset: String = "", hint: String? = null,
    style: TextSlotStyle,                 // the design's font/size/weight/colour (reference values)
    text: String? = null,                 // default: Profile.me.text(TextSlotID(field, index, widget, preset, hint))
    modifier: Modifier = Modifier,
    maxLines: Int = 1, softWrap: Boolean = false, autoSizeMin: Float? = null,   // .lineLimit / .minimumScaleFactor
    textAlign: TextAlign? = null,
)
```
It: tunes `style` by `LocalWidgetTextStyle` + `LocalCardInk` + `LocalCardAccent` (`TextSlotStyle.tuned`), applies
`uppercase`/`italic`/`tracking`, draws with `Text(...)`, redacts under `LocalGhostData`, registers its bounds in
`LocalSlotRegistry` when `LocalTextEditMode` is on, and registers `ProfileField.contactURL` as a link slot otherwise.
For custom-drawn text (gradient fills, per-glyph animation) use `Modifier.editableSlot(id: TextSlotID, style: TextSlotStyle)`
which only registers the frame + link. `EditableParagraph(field, style, reserve, widget, anchor, modifier)` stays a composable.
`TextSlotStyle` fields: `size: Float, weight: FontWeight, face: CardFont, color: Color, align: TextAlign, tracking: Float,
lineSpacing: Float, uppercase: Boolean, corner: Float, italic: Boolean, tilt: Double` and `val textStyle: TextStyle`.

`WidgetInstance` construction: the Swift init with optional `w`/`h` is `WidgetInstance.make(kind, x = , y = , w = , h = , id = )`
(companion factory in model/WidgetModel.kt); the data-class primary constructor takes every field explicitly.

## 12. Deviations log — what wave 1 actually named things (read before wave 2)

Kotlin's `Enum.name` is final, so every Swift enum `name` label became **`displayName`**: `CardInk`, `Palette`,
`CornerStyle`, `BackdropStyle`, `BackdropEffect`, `StripStyle`, `CardFont`, `TextTint`, `TextScale`, `TextAlignment`,
`WidgetSurface`, `PlatePattern`. (`WidgetKind.title`/`label`s unchanged.)
`SocialType`, `ContentFormat`, `StarSocial`, `StarFormat`, `WizStep` are **sealed classes** with lowercase `object`
cases — they keep `.name` ("Instagram"), plus `.raw`, `.ordinal`, `X.entries`, `X.from(raw)`; exhaustive `when` works.
- theme `TextAlign` → **`TextAlignment`** (`leading/center/trailing`, `.text: TextAlign`, `.frame`, `.centered`).
- `ProfileField.name` → **`ProfileField.personName`** (raw stays `"name"`). `ProfileField.keyboard: KeyboardType`.
- `Ph.package` → `` Ph.`package` ``.
- Tuples → data classes: `CardTheme.duoColors: DuoColors(bg, ink)?`, `backdropColors: BackdropColors(top, bottom)`,
  `theme.marbleInk: MarbleInk(vein, bleed)`, `customColor`/`backdropHSB: HSB(h, s, b)`, `CardStore.restore(): Restored(pages, theme, index)?`,
  `PhotoStore.dominantTone(): HSB?`, `StarFlow.goto(i): Pair<FlowScreen?, FlowDialog?>`.
- `CardTheme` mutators return copies: `theme = theme.setDuo(d)`, `setBackdropColor(h,s,b)`, `clearBackdropColor()`,
  `setBackdropHex(text): CardTheme?` (null = unparsable).
- `WidgetInstance.make(kind, x=, y=, w=, h=, id=)`; `scale(toWidth)`/`resetAspect()`/`withRect(r)` return copies; fields are `var` but treat as immutable.
- `EditHistory` is a class with `record(before)`, `undo(current)`, `redo(current)`, `canUndo`, `canRedo` (state-backed).
- Intake value types are immutable data classes: `Profile.me.updateIntake { d -> d.copy(...) }`. No `binding()` — use `raw(id)`/`set(id, v)`/`commit(id)`.
- `Profile.me.values/list/notes` are state maps; `Profile.me.creator`, `editing`, `intake`, `sampleFamilies` are state.
- `Portfolio.shared`: `creatorImage(slot)`, `workImage(slot)`, `Video.file: java.io.File`, `PickedMovie(uri)`, `addVideo(uri)`; `Portfolio.creatorSlots`.
- `StarCampaign.logo/cover: Int` (drawable ids), `timeline: List<Pair<String,String>>`, `deadline: Long?`.
- `StarFlow`: `FlowScreen.Wizard(kind)`, `.Reveal`, `.Register`, `.Accept`, `.StarProfile`, `.Kyc`; `StarRow.icon: Ph`; `LocalStarFlow`.
- `ClipInvocation.consume(uri: Uri)` / `consume(url: String)`; `AppRuntime.isClip == false`.
- `PhotoStore`: `set(images, from, order, id)`, `clear(slot, id)`, `fit(slot, id)`, `setFit(f, slot, id)`, `uiImage(slot, id)`,
  `userImage(slot, id)`, `library(i)`, composables `image(i, id = null, modifier)`, `avatar(modifier)`; `LocalPhotoStore` is **nullable**;
  `PhotoSlotButton(theme, widgetID, slot, order, labelled, scale)`, `BackgroundPickButton(theme, compact, modifier, onPicked: (HSB?) -> Unit)`,
  `PhotoUploadButton(theme, compact)`, `PhotoFitSurface(theme, widgetID, slot, size)`, `PhotoFitCatcher(theme, scale)`, `PhotoFitCatcher.maxZoom`.
- `PhotoLift.lift()` and `SubjectLift` always yield "no cutout" (stubs). `CutoutCache.shared.result(bitmap).isCutout`.
- `PhotoLib`, `ImageCache`, `RemotePhoto(url, modifier)`, `RemoteLogo(url)`, `PhotoTile`, `WorkDeepStats`, `PosterPlate`, `PosterSheet`,
  `WidgetBody`, `AvatarOrb`, `StatColumn`, `FollowerPills`, `SystemPending` live in `co.salehere.starcard.ui.widgets` (WidgetShared.kt).
- `Modifier.linkSlot(url: String?, slop: Float = 0f)`; `Modifier.verifySlot(on)` is `@Composable` (theme/Signature.kt); `Contact.tel/mail/line(): String?`.
- `EditableText(...)` / `Modifier.editableSlot(id, style)` / `EditableParagraph(field, style, reserve, widget, anchor, modifier)` per §11;
  `TextSlotStyle.align` is Compose `TextAlign`; `TextSlotStyle.textStyle`; `TextStyle.legibilityHalo(color, size, density = 1f)`;
  `TextEditBar(id, theme, style, onStyle: ((WidgetTextStyle) -> WidgetTextStyle) -> Unit)?, onDone)`; `TextTools.onStyle` same shape.
- `Modifier.redacted(on)`, `Modifier.dataValue()` (components/Glass.kt, ui/editor/EditableText.kt).
- `GlassPanel(tint, tintStrength, veil, radius, interactive, modifier, content)`; `WidgetLabel(text, trailing: (@Composable () -> Unit)?, modifier)`.
- `EdGrain(count, opacity, tint, modifier)` lives in theme/CardTheme.kt; `VerifiedFacts` object in theme/VerifiedFacts.kt (`sheetURL: String`, `labForce: Boolean`);
  `TextBlockWeight` (= `TextBlock.weight`) in ui/editor/TextTools.kt; `SocialType.simulateFetch(seed)` in model/Intake.kt.
- `TextFit.metrics/natural/capped(measurer, …)` take a `TextMeasurer` — get one with `TextFit.rememberMeasurer()`.
- `Modifier.negativePadding(all)` (internal, theme/Signature.kt) when you need `.padding(-x)`.
- `Haptics.impact(Haptics.Style.light)` — do not redefine `Haptics` (CardScreen.swift line 3300 is already ported).
- `Modifier.blur`/`saturationLayer` are API 31+ only (emulator is 36 — fine).

## 13. Ownership matrix — wave 2 (all view files)

| Porter | Swift → Kotlin |
|---|---|
| W1 hero/art | Views/Widgets/HeroWidgets.swift → ui/widgets/HeroWidgets.kt · ArtWidgets.swift → ArtWidgets.kt · CutoutWidgets.swift → CutoutWidgets.kt |
| W2 about/text/work | AboutWidgets.swift, ContentWidgets.swift, TextWidgets.swift, WorkWidgets.swift, GenZWidgets.swift, SocialWidgets.swift → ui/widgets/<same>.kt |
| W3 proof/booking | ProofWidgets.swift, ProofWorkVariants.swift, VerifiedSealWidget.swift (everything except `VerifiedFacts`; **must define the real `VerifiedSeal(radius, punch, tint, compact, modifier)`**), BookingWidgets.swift |
| W4 gallery/insight | GalleryWidgets.swift, ShowcaseWidgets.swift, InsightWidgets.swift, InsightPosterWidget.swift |
| W5 posters | PopWidgets.swift, RateArtWidgets.swift, StatPosterWidget.swift, NichePosterWidget.swift, ContactPosterWidget.swift |
| W6 editorial | EditorialWidgets.swift (everything except `EdGrain`), PosterWidgets.swift |
| S1 shell | Views/SaleHere/SHKit.swift → ui/salehere/SHKit.kt · SaleHereShell.swift · StarHomePage.swift · StarCampaignPage.swift · SaleHereProfilePage.swift → ui/salehere/<same>.kt · **ContentView.swift → ContentView.kt (root package; replaces the placeholder: `ContentView`, `StarCardIntent`, `StarCardSpace`, `PageSlide`)** |
| S2 flow | Views/SaleHere/StarFlow/*.swift → ui/salehere/starflow/<same>.kt (StarGlassKit, StarWizard, StarPage (+`StarCardHero`), RegisterFormPage, AcceptPage, KycMockPage, FlowLab (+`LabFab`), StarHeader (+`StarGround`), StarCardStage, StarTopicFill) |
| S3 editor | Views/CardScreen.swift → ui/CardScreen.kt (the whole file: `CardScreen`, `CardNotice`, `SpectrumPicker`, `TrackSlider`, `PhotoEffectSwatch`, `CanvasGrid`, `HandleGrip`, `InkSwatch`, `DuoDot`, `BackdropSwatch`, `TopicFillRequest`; NOT `Haptics`) |
| S4 dock | Views/Editor/EditorDock.swift, ControlSheet.swift (`WidgetThumb`), WidgetGallery.swift, PressDragCatcher.swift → ui/editor/<same>.kt |
| S5 gallery | Views/CardGallery.swift, CardPreviews.swift (`CardStripPreview`, `CardFramePreview`, `TemplateThumbs`, `VerticalDashes`), TemplatePicker.swift (`TemplateWall`), ContactSheet.swift, VerifySheet.swift (`VerifiedBand`, `VerifiedTab`), SafariSheet.swift (`LinkTarget`; open with Custom Tabs/`Intent.ACTION_VIEW`), Views/Export/CardA4Export.swift + CardSharePreview.swift → ui/export/<same>.kt |
| S6 profile | Views/Profile/ProfileKit.swift, ProfileFlow.swift (+`WizardHeading`, `LocalWizardHeading`), ProfileEditor.swift, ProfileSection.swift, Sections/*.swift → ui/profile/<same>.kt, ui/profile/sections/<same>.kt |

Not ported (debug-only): `Views/Widgets/EditorialLab.swift`, `VerifiedLab.swift`.

Composable signature rule for every screen/widget: parameters keep the Swift labels as Kotlin parameter names
(`onBack`, `onPick`, `onFinish`, `campaign`, `hosted`…), callbacks are `() -> Unit` / `(T) -> Unit`, optional callbacks are
nullable with default `null`, `@ViewBuilder` content is the last parameter, `modifier: Modifier = Modifier` right before content.
Widgets take exactly the Swift init parameters (`theme: CardTheme`, `size: Size` / `width: Float`) + `modifier`.

## 14. Wave 2 relaunch — READ THIS FIRST (supersedes anything above that conflicts)

### 14.1 Already written by the lead — use, never redefine
- `ui/widgets/WidgetChrome.kt`: `WidgetChrome(placed: Placed, theme: CardTheme, modifier)`, `slab(theme): Color`,
  `object TextBlockSpec { inset = 4f; radius = 10f }` (Swift `TextBlock.inset/radius`; `TextBlock.weight` = `TextBlockWeight` in ui/editor/TextTools.kt).
  The widget porter writes `@Composable fun TextBlock(theme, size, modifier)` in TextWidgets.kt — do NOT create an `object TextBlock`.
- `ui/widgets/WidgetKit.kt` — every helper that Swift shares ACROSS widget files. Owners of the Swift files these came
  from must **skip** them; everyone calls these:
  - `FlowLayout(spacing = 6f, modifier, content)`, `FlowChips(items, spacing, modifier, chip: (String) -> Unit)` (AboutWidgets.swift)
  - `Ed` object (all colours, `Ed.fitted(measurer, text, weight, face, width, cap, floor): Float` — get `measurer` from
    `TextFit.rememberMeasurer()`), `Ed.skin(surface, paper, ink, theme = null, ghostOnPaper = White): EdSkin`, `EdSkin`,
    `EdHalftone(step, dot, opacity, modifier)`, `EdText(slot, preset, hint, style, lines = 1, minScale = 0.62f, modifier)`,
    `EdPhoto(slot, mono = false, depth = 10f, modifier)`, `EdPlace(x, y, w, h, size: Size, tilt = 0.0, align = TopCenter, modifier, content)`
    (a child of a `Box` sized `size`), `EdSelectionHandles(tint, dot, line, modifier)`, `Modifier.grayscale()` (EditorialWidgets.swift; `EdGrain` is in theme/CardTheme.kt)
  - `CutoutPlane` (sealed: `CutoutPlane.Subject(image: Bitmap, own)`, `CutoutPlane.Framed`; `.subject: Bitmap?`, `.isSample`),
    `CutoutSample.image`, `cutoutPlane(store, slot, widget, lift = false)`, `cutoutLifting(store, slot, widget, lift)`,
    `CutoutSubject(image: Bitmap, height, d, drift, shadow = true, modifier)`, `CutoutStatus(plane, theme, lifting = false, modifier)` (CutoutWidgets.swift)
  - `StatPosterSkin` + `StatPosterSkin.make(surface, theme, on: InkStyle)` (StatPosterWidget.swift)
  - `Deal` object, `ContactLine(label, icon /*SF name → SFSymbol()*/, field)` + `ContactLine.all`, `QRCode(text, tint, modifier)`, `QRCodeCache.render(text): Bitmap?` (BookingWidgets.swift)
  - `VerifiedSeal(radius, punch, tint, compact, modifier)`, `MiniSeal(size, color, modifier)`, `SealScallop(petals, depth)` (a `Shape`; `.path(size, origin)`),
    `CheckStroke.path(w, h, origin)`, `RingText(text, radius, size, color, modifier)`, `Guilloche(color, modifier)`, `DotLeader(color, modifier)` (VerifiedSealWidget.swift)
  - `BrandPlate(brand, side, modifier)` (ProofWidgets.swift)
- `ui/Press.kt`: `Modifier.tap(enabled, onClick)` (plain button), `Modifier.dockPress(enabled, onClick)` (= `DockPress`),
  `Modifier.pkRowPress(enabled, onClick)` (= `PKRowPress`), `Modifier.pkDimPress(enabled, onClick)` (= `PKDimPress`).
  Every `Button { } label: { }.buttonStyle(X())` becomes `label-content` with `Modifier.x { action }` on its outer container.
- There are **no widget stubs** any more. `WidgetBody` (WidgetShared.kt) already calls every widget by its Swift name — grep it for your
  widgets' exact call shape (`ArtPortrait(theme, size)`, `SocialChips(theme, size.width)`, …) and match it.

### 14.2 The one rule for calling another porter's composable (deterministic — apply it by reading the Swift source)
Kotlin signature of a Swift `struct X: View` = its **non-private stored properties that are not `@State`/`@Environment`/`@FocusState`**,
in declaration order, same names, same defaults, then `modifier: Modifier = Modifier`, then the `@ViewBuilder` content (if any) last.
- `let onBack: () -> Void` → `onBack: () -> Unit`; optional closure `var onX: (() -> Void)? = nil` → `onX: (() -> Unit)? = null`.
- `@Binding var foo: T` → two params in place: `foo: T, onFooChange: (T) -> Unit`.
- `CGFloat`/`CGSize`/`URL`/`UIImage` → `Float`/`Size`/`String`/`Bitmap`; Swift enum-with-payload params → the sealed class.
- If the Swift struct has a custom `init(...)`, use that init's labels/order instead.
Call sites use **named arguments** for everything except the first 1–2 obvious positional ones, so order slips don't break builds.
Views that were given explicit signatures in §13 prompts (CardScreen, CardGallery, TemplatePicker, StarWizard, StarPage, …) follow this same rule.

### 14.3 Cross-porter screen helpers (owner → users)
- S2 `ui/salehere/starflow/StarGlassKit.kt`: `GL` object (+ `GL.serif(size)` → `serifItalic`), `GlassOrbs`, `GlassTitle`, `GlassChip`, `GlassCircleButton`,
  `GlassPrimaryButton`, `GlassLink`, `StarGlassCard`, `WzChip`, `WzTile`, `WzInput`, `NudgeChips`, `FlowModal`, `FlowButton`, `FlowToast`, `StarPill`, `VerifiedPill`, `GhostSlot` → used by S1, S5.
- S2 `StarHeader.kt`: `StarHeader`, `StarGround` → used by S1, S5. S2 `StarTopicFill.kt`: `StarTopicFill` → used by S3. `TopicFillRequest` is S3's (CardScreen.kt).
- S1 `ui/salehere/SHKit.kt`: `SH`, `SHNavBar`, `SHBarLogo`, `SHBarIcon`, `SHRedButton`, `SHOutlineButton`, `SHAvatar`, `SHMockUser` → used by S2.
  S1 `StarHomePage.kt`: `StarBrandLogo` → used by S2.
- S6 `ui/profile/ProfileKit.kt`: `PK` + all `PK*` composables (`PKWrap`, `PKReveal`, `PKPrimaryButton`, `PKCircleButton`, `PKFactStrip`, …) → used by S2.
  S6 `ProfileEditor.kt`: `MediaTile`, `PendingTile`, `AddTile`, `VideoSheet` → used by S2. S6 `ProfileFlow.kt`: `SectionScroll` → used by S6 sections.
- S5 `ui/CardPreviews.kt`: `CardStripPreview`, `CardFramePreview`, `TemplateThumbs`; `ui/TemplatePicker.kt`: `TemplateWall`;
  `ui/VerifySheet.kt`: `VerifySheet`, `VerifiedBand`, `VerifiedTab`; `ui/ContactSheet.kt`: `ContactSheet`; `ui/SafariSheet.kt`: `SafariSheet`, `LinkTarget`;
  `ui/export/*`: `CardExport`, `CardSharePreview` → used by S2, S3.
- S4 `ui/editor/*`: `EditorDock`, `DockMode`, `DockMainItem`, `DockSheet`, `DockRow`, `DockSegment`, `WidgetGallery`, `WidgetThumb`, `PressDragCatcher` → used by S3.
- S1 root `ContentView.kt`: `StarCardIntent`, `StarCardSpace`, `Modifier.pageSlide(progress)` → used by S2.
Owners make these **public** (not `private`/`internal`) and follow §14.2 exactly.

### 14.4 Correction (lead)
`Color.opacity(x)` in theme/ColorTools.kt now **multiplies** the existing alpha, exactly like SwiftUI. Port `.opacity()` calls
literally from Swift; do not multiply by `color.alpha` yourself. `Symbols.kt` now maps every SF name the Swift code uses
(play, skip, phone, message, envelope, trash, heart, bookmark, fork.knife, tshirt, dumbbell, …) to real Phosphor icons.
