# Slydee — Master Blueprint

> **Single source of truth for the Slydee iOS app.** Generated from the actual codebase, not the aspirational spec.
> Scope: every module, model, and decision built across Phases 1–3 + the Research feature.

---

## 0. نظرة عامة (Arabic Overview)

**Slydee** تطبيق iOS أصلي يحوّل أي فكرة (موضوع، ملف، صورة، أو بحث ويب) إلى:
1. **عرض تقديمي** احترافي بثوانٍ.
2. **بحث / تقرير** منسّق (ميزة البحوث الجديدة).

أول تطبيق مصمّم أصلاً للمحتوى **العربي + الإنجليزي + المختلط** معاً. مبني بالكامل بـ SwiftUI + SwiftData على iOS 26.5، Swift 6.

**حالة المشروع:** الكود مكتمل عبر 3 مراحل + ميزة البحوث. يبني نظيفاً (صفر تحذيرات)، يقلع بالمحاكي بدون كراش. **لم يُختبَر على جهاز حقيقي ولا على TestFlight، والذكاء الاصطناعي الفعلي غير موصول بعد** (يعمل بمولّد تجريبي mock — نقطة الوصل جاهزة).

التفاصيل التقنية الكاملة بالإنجليزية أدناه (لمطابقة أسماء الكود).

---

## 1. Document Metadata

| Field | Value |
|---|---|
| App name | Slydee |
| Bundle ID | `com.slydee.app` |
| Repo | `git@github.com:mraad500/Slydee.git` (branch `main`) |
| Codebase size | 79 Swift files, ~6,946 LOC + `Localizable.xcstrings` |
| Commits | `234b920` Initial · `60736f9` Phase 1 · `be51802` Phase 2 · `3137ff4` Phase 3 · **Research feature = uncommitted** |
| Toolchain | Xcode 26.5, Swift 6.3.2, iOS SDK 26.5, macOS 26.x |
| Author | Mohammed Raad Aziz ("Hamoudi"), solo founder of AiQo |

---

## 2. Product Scope & Phase History

Slydee was built in strict phases (founder discipline; later phases were consciously fast-tracked by the founder ahead of the original validation gates).

| Phase | Commit | Delivered |
|---|---|---|
| **1 — MVP** | `60736f9` | Topic/File/Image input → AI deck generation → SwiftData persistence → frame-based renderer → paged viewer → 16:9 vector PDF → Library → Settings (Keychain keys) → EN/AR localization |
| **2 — Editor** | `be51802` | Direct-manipulation slide editor: select/drag/pinch/rotate blocks; text inspector; add image (PhotosPicker) / SF-Symbol stickers / Swift Charts; per-block entrance animations played in Present mode; slide filmstrip add/dup/delete; slide inspector (background/transition/notes); SwiftData undo/redo |
| **3 — Power** | `3137ff4` | Google Programmable Search in the Create flow; native ZIP writer + image-based `.pptx` export; CloudKit-ready resilient persistence (iCloud entitlement) |
| **Research** | uncommitted | "Research Papers & Reports" (البحوث): config → mock generation → formatted reader → CoreText paginated PDF / clipboard; appears in shared Library; glassmorphic UI |

**Not built** (require new Xcode app-extension targets — deliberately deferred to avoid pbxproj corruption): Widgets (spec §10.4), Live Activities (§10.5).

### Verification status (be precise about this)
- ✅ Verified: clean Swift 6 build, **zero compiler warnings**; launches in iPhone 17 Pro simulator without crash; SwiftData schema migration safe; Home/UI renders on-brand.
- ❌ NOT verified: physical device, TestFlight, real AI output (mock only), PDF/PPTX opening in PowerPoint/Keynote, on-device Foundation Models, Claude/OpenAI/Google live calls, CloudKit actual sync (needs the founder's iCloud container provisioning), RTL visual fidelity on device.

---

## 3. Tech Stack

| Layer | Choice |
|---|---|
| UI | SwiftUI (iOS 26.5), `@Observable`, `NavigationStack`, `Tab` API, `.fullScreenCover`, glassmorphism via `.ultraThinMaterial` |
| Persistence | SwiftData (`@Model`), JSON-string payloads for complex content, CloudKit (`.automatic`) with local fallback |
| On-device AI | Apple **Foundation Models** (`FoundationModels`, `@Generable`, `LanguageModelSession`) — English decks |
| Cloud AI | Claude Messages API (Arabic/Mixed, prompt-cached), OpenAI Chat Completions (fallback) |
| Web | URLSession via `APIClient`; Google Programmable Search JSON API |
| OCR | Vision (`VNRecognizeTextRequest`, ar+en) |
| Doc import | PDFKit (PDF), plain-text family |
| Charts | Swift Charts (`BarMark`/`LineMark`/`SectorMark`) |
| Export | CoreGraphics PDF (decks, vector via `ImageRenderer`), custom OOXML + native ZIP (`.pptx`), CoreText pagination (research PDF) |
| Security | Keychain (Security framework) — API keys only, never UserDefaults/hardcoded |
| Concurrency | Swift 6 language mode, strict checking, `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` |
| No 3rd-party deps | SPM-only policy; zero external packages used |

---

## 4. Architecture Principles & Conventions

These are **load-bearing rules**. Violating them breaks the build or the app.

### 4.1 Clean MVVM
- Views are SwiftUI structs (MainActor by default).
- View models: `@MainActor @Observable final class …ViewModel`. They own flow state, validation, async orchestration, and the `ModelContext` interaction. Pattern mirrors across `CreateViewModel`, `EditorViewModel`, `ResearchConfigViewModel`, `SettingsViewModel`.
- Flow containers (`CreateView`, `ResearchFlowView`) hold the VM via `@State`, switch on a `phase`/`step` enum, drive a toolbar, and push the result via `.navigationDestination(item:)`.

### 4.2 The concurrency boundary (most important rule)
The Xcode 26 template sets `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, so **every type is MainActor-isolated unless marked `nonisolated`**. SwiftData `@Model` accessors run *nonisolated*; therefore:

> **All data/model/value/token/utility types are declared `nonisolated`.**

This covers: every enum/struct in `Models/` value layer (`BlockContent`, `RelativeFrame`, `Enums`, `SlideBackground`, `BlockAnimation`, `ResearchModels`, `Template`, `WebResult`, `StickerCatalog`, `AppSettings`, `AppLanguage`, `LanguageDetector`), the design tokens (`Color` extensions, `SlydeeFont`, `FontSize`, `Spacing`, `Radius`), `JSONCoding`, all AI generators + requests/results, `KeychainStore`, `APIClient`, `ZIPArchive`. View models stay `@MainActor`; exporters that use `ImageRenderer`/UIKit are `@MainActor`. `L` (LocalizedStringKey table) stays MainActor (views-only).

A regression caused by ignoring this (CloudKit + non-optional relationships) was caught and fixed — see §12.

### 4.3 Primitive persistence
Complex/polymorphic content is **JSON-encoded into `String` columns** via `JSONCoding` (nonisolated, `JSONEncoder/Decoder`). Keeps the SwiftData schema all-primitive (UUID/String/Int/Double/Date/Data) → reliable migration + CloudKit-safe. Examples: `Block.frameJSON`/`contentJSON`/`animationJSON`, `Slide.backgroundJSON`, `ResearchDocument.bodyJSON`.

### 4.4 SwiftData + CloudKit rules (enforced)
- Every stored property has a default value.
- No `@Attribute(.unique)`.
- **All relationships optional** — `Deck.slides: [Slide]?`, `Slide.blocks: [Block]?` (to-many must be optional for CloudKit). Mutations go through helpers (`addSlide`, `addBlock`, `removeBlock`); reads through `orderedSlides`/`orderedBlocks` (sorted, nil-coalesced). Never append to the optional directly.
- `ResearchDocument` has **no relationships** (self-contained, JSON body) — inherently CloudKit-safe.

### 4.5 Xcode project format
`project.pbxproj` uses `objectVersion = 77` with a **`PBXFileSystemSynchronizedRootGroup`**: any `.swift` file added under `Slydee/` is auto-included in the target — no pbxproj surgery for new files. Adding **targets** (Widgets/Live Activities) *does* require risky pbxproj edits → deferred.

### 4.6 Quality bar
Swift 6 strict concurrency, **zero compiler warnings** (the only build-log "warning" is a benign AppIntents metadata note — no AppIntents framework used). Verified via `xcodebuild … clean build` after every milestone.

---

## 5. Project Structure

```
Slydee/
├── App/
│   ├── SlydeeApp.swift              @main; container via SlydeePersistence
│   └── RootView.swift               TabView: Home / Library / Settings + UI-language locale modifier
├── Core/
│   ├── AI/                          generation pipeline (decks + research)
│   ├── DesignSystem/
│   │   ├── Colors.swift  Typography.swift  Spacing.swift
│   │   └── Components/   SlydeeButton  SlydeeCard  GlassCard  MascotView
│   ├── Export/                      PDFExporter  PPTXExporter  ZIPArchive  ResearchPDFExporter  ShareSheet
│   ├── Extensions/                  JSONCoding
│   ├── Input/                       SourceTextExtractor (PDF/txt)  ImageTextRecognizer (Vision OCR)
│   ├── Localization/                AppLanguage  L  LanguageDetector
│   ├── Networking/                  APIClient  KeychainStore  GoogleSearchClient
│   └── Persistence/                 SlydeePersistence (CloudKit-resilient container)
├── Features/
│   ├── Home/        HomeView  DeckCard
│   ├── Create/      CreateView  CreateViewModel  InputStep  ConfigureStep  GenerateStep  SearchInputView
│   ├── Editor/      EditorView  EditorViewModel  EditableSlideCanvas  TextInspectorView
│   │               StickerPickerView  ChartInspectorView  AnimationInspectorView  SlideInspectorView
│   ├── Preview/     DeckPreviewView  SlideCanvas (+ BlockView + BlockContentView)
│   ├── Library/     LibraryView (decks + research unified)
│   ├── Settings/    SettingsView  SettingsViewModel
│   ├── Templates/   TemplatePreview
│   └── Research/    ResearchFlowView  ResearchConfigViewModel  ResearchConfigView
│                    ResearchGeneratingView  ResearchReaderView  ResearchCard
├── Models/          Deck  Slide  Block  BlockContent  BlockAnimation  Enums  SlideBackground
│                    Template  AppSettings  WebResult  StickerCatalog
│                    ResearchDocument  ResearchModels
├── Resources/       Localizable.xcstrings (en + ar)
├── Assets.xcassets  AppIcon (light/dark/tinted)  AccentColor
└── Slydee.entitlements   iCloud (CloudKit container iCloud.com.slydee.app) + aps-environment
```

---

## 6. Data Model Layer

### 6.1 Presentations
| Type | Kind | Key fields |
|---|---|---|
| `Deck` | `@Model` | `id, title, createdAt, updatedAt, language: AppLanguage, theme: ThemeID, slides: [Slide]?` (cascade), `coverImageData`, `originalInput`; `orderedSlides`, `addSlide`, `touch()` |
| `Slide` | `@Model` | `id, deck: Deck?, index, layout: SlideLayout, transition: TransitionType, notes, language, backgroundJSON, blocks: [Block]?` (cascade); `background: SlideBackground` (computed), `orderedBlocks`, `addBlock`, `removeBlock` |
| `Block` | `@Model` | `id, slide: Slide?, type: BlockType, rotation, opacity, zIndex, frameJSON, contentJSON, animationJSON`; computed `frame: RelativeFrame`, `content: BlockContent?`, `animation: BlockAnimation?`; `.text(...)` factory |
| `BlockContent` | enum (Codable) | `.text(TextContent) / .image(ImageContent) / .sticker(id) / .shape(ShapeContent) / .chart(ChartContent)` |
| `TextContent` | struct | text, fontToken, size, weight `SlydeeFontWeight`, colorHex, align `TextAlign`, language |
| `RelativeFrame` | struct | x/y/width/height in 0…1; `.absolute(in:)` → CGRect |
| `BlockAnimation` | struct | kind (none/fade/slide/scale/bounce), edge, duration, delay |
| `SlideBackground` | enum | `.theme / .solid(hex) / .gradient(hexes)` → `view(theme:)` |
| `Template` | struct | id, name, `theme: ThemeID`; `TemplateCatalog.all` = 8 |
| `Enums` | — | `ThemeID` (classic/sun/sky/mint/lavender/peach/midnight/editorial; each exposes `*Hex` + `Color`), `SlideLayout` (8), `TransitionType`, `BlockType`, `TextAlign`, `SlydeeFontWeight` |

### 6.2 Research
| Type | Kind | Key fields |
|---|---|---|
| `ResearchDocument` | `@Model` | `id, title, topic, createdAt, updatedAt, language, tone: ResearchTone, lengthMode: ResearchLengthMode, lengthValue, bodyJSON`; computed `sections: [ResearchSection]`, `plainText`, `wordCount`, `displayTitle`, `touch()` — **no relationships** |
| `ResearchSection` | struct | `id, style: ResearchSectionStyle, text` |
| `ResearchSectionStyle` | enum | title / heading / subheading / body / quote |
| `ResearchTone` | enum | academic / analytical / descriptive (+ EN/AR descriptors) |
| `ResearchLengthMode` | enum | words / pages (range, step, `targetWordCount` ≈350 w/page) |

### 6.3 Misc models
`AppSettings` (UserDefaults-backed: `UILanguage`, `GeneratorPreference`, `appVersion`), `WebResult` (search result + `asSourceText` citation), `StickerCatalog` (3 categories of SF Symbols).

Registered schema (`SlydeePersistence`): `Schema([Deck, Slide, Block, ResearchDocument])`.

---

## 7. Design System

- **Colors** (`Color` hex init + tokens): `slydeeCream #F7F2E8` (bg), `slydeeInk #0F0F0F`, `slydeeSun #FFD93D` (accent/CTA), `slydeeSky #A5D8FF`, `slydeeMint #A8E6CF`, `slydeeLavender #C8B6FF`, `slydeePeach #FFB199`, plus `slydeeSurface`, `slydeeInkMuted`, `slydeeHairline`; semantic success/warning/info. `hexString` (UIColor) for editor color pickers.
- **Typography** (`SlydeeFont`): language-aware `title/heading/body/emphasis/mono/scaled(size:weight:lang:)`; system face (SF Pro / SF Arabic) — IBM Plex Arabic is a future swap point (`arabicCustomFamily`). `FontSize` scale (display 34 → caption 13).
- **Spacing/Radius**: 4-pt scale `xxs…xxxl`; radii sm/md/lg/pill.
- **Components**: `SlydeeButton` (primary/secondary/ghost, pill, `SpringButtonStyle`), `SlydeeCard` (solid surface), `GlassCard` (glassmorphism: `.ultraThinMaterial` over cream tint, soft shadow, hairline, continuous corners; `.glassCard()` modifier), `MascotView` (vector smiley via Canvas — eyes, cheek dot, smile).
- Empty/loading states are character-driven (mascot), per brand voice.

---

## 8. AI Generation Pipeline (Decks)

```
GenerationRequest(sourceText, language, slideCount, tone)
        │
        ▼  GeneratorFactory.generator(for:)            ← honors AppSettings.generatorPreference
   ┌─ english → FallbackGenerator(FoundationModelGenerator, MockGenerator)
   └─ arabic/mixed → FallbackGenerator(ClaudeGenerator, FallbackGenerator(OpenAIGenerator, MockGenerator))
        │
        ▼  any AIGenerator.generate() async throws -> GeneratedDeck
        ▼  DeckBuilder.build(...) @MainActor          ← maps to Deck/Slide/Block w/ relative frames
        ▼  ModelContext.insert + save
```

- **`AIGenerator`** protocol (`Sendable`): `generate(_:) async throws -> GeneratedDeck`. `GeneratedDeck/Slide` are `nonisolated Sendable`. `GenerationError` (LocalizedError): cancelled / unavailable / invalidResponse / missingAPIKey / network.
- **`FoundationModelGenerator`** — `SystemLanguageModel.default.availability` guard; `LanguageModelSession { instructions }`; `session.respond(to:generating: GenDeck.self)`. `GenDeck`/`GenSlide` are `@Generable` with `@Guide` descriptions (`SlideJSONSchema.swift`).
- **`ClaudeGenerator`** — Anthropic `/v1/messages`, model `claude-sonnet-4-6`, system prompt sent as a **cacheable block** (`cache_control: ephemeral`), `anthropic-version: 2023-06-01`. Parses via `DeckJSONParser`.
- **`OpenAIGenerator`** — `/v1/chat/completions`, `response_format: json_object`.
- **`DeckJSONParser`** — tolerant: extracts the first balanced `{…}` from model prose, decodes DTOs, maps to `GeneratedDeck`, per-slide language tagging for mixed.
- **`PromptBuilder`** — English instructions (Foundation), Arabic system prompt (فصحى), mixed prompt, shared JSON schema, tone descriptors.
- **`DeckBuilder`** (`@MainActor`) — reference canvas 1280pt; per-`SlideLayout` relative frames (titleOnly/sectionDivider/quote/twoColumn/titleContent…), per-block language via `LanguageDetector` for mixed, theme hex colors, RTL alignment.
- **`MockGenerator`** — deterministic, language-aware; permanent offline fallback so generation never hard-fails.

### Research pipeline (parallel, mock-only today)
`ResearchRequest → ResearchGeneratorFactory.generator(for:) → any ResearchGenerator → GeneratedResearch(title, [ResearchSection]) → ResearchDocument`. `MockResearchGenerator` builds title→abstract→intro→N sections→conclusion→references, scaled by `targetWordCount`, EN/AR/Mixed aware. **Real-AI wiring point:** `ResearchGeneratorFactory` (documented TODO, mirrors `GeneratorFactory`).

---

## 9. Feature Modules

### 9.1 Home (`HomeView`)
Cream scroll; header (mascot + tagline); **two glass entry tiles** side by side — "New Presentation" (→ `CreateView`) and "New Research" (→ `ResearchFlowView`); horizontal "Recent" decks (`DeckCard`, `@Query Deck`); "Templates" row (8); mascot empty state.

### 9.2 Create flow (`CreateView` + `CreateViewModel`)
3 steps: **Input** (`InputStep`: Topic editor + suggestions / File import `SourceTextExtractor` / Image OCR `ImageTextRecognizer` / **Search** `SearchInputView` Google → cited source) → **Configure** (`ConfigureStep`: language, slide count 3–20, template, tone) → **Generate** (`GenerateStep`: pulsing mascot + status ticker, cancel, error/retry). Result pushes `DeckPreviewView`.

### 9.3 Editor (`EditorView` + `EditorViewModel`)
Top bar (Done, undo/redo via SwiftData `undoManager`, Add menu, slide add/dup/delete, slide inspector). Center = `EditableSlideCanvas` (tap select; drag move; `MagnifyGesture` resize; `RotateGesture`; transient gesture state committed on end via `commitTransform`). Filmstrip thumbnails. Context bar per selection. Inspectors: `TextInspectorView` (content/size/weight/color/align/lang/opacity), `ChartInspectorView` (type + data rows), `AnimationInspectorView` (entrance kind/edge/timing), `SlideInspectorView` (background theme/solid/gradient, transition, notes). Add: text, image (`PhotosPicker`), sticker (`StickerPickerView` over `StickerCatalog`), chart.

### 9.4 Renderer (`SlideCanvas`)
Layout-agnostic, frame-based. `SlideCanvas` (background + ordered `BlockView`s at 16:9 size). `BlockView` positions + plays entrance animation. `BlockContentView` renders text (scaled font, RTL), image (`UIImage`), sticker (SF Symbol), shape, **Swift Charts**. Reused by viewer, thumbnails, PDF/PPTX export, editor. `DeckPreviewView`: paged `TabView`, pinch-zoom, **Present mode** (`fullScreenCover`, animated), Edit entry, PDF/PPTX share menu.

### 9.5 Library (`LibraryView`)
Unified `LazyVGrid`: `@Query Deck` (`DeckCard`) **+** `@Query ResearchDocument` (`ResearchCard`). Search across both. Context menus — decks: rename/duplicate/export PDF/export PPTX/delete; research: rename/export PDF/delete. Navigation: `DeckPreviewView` / `ResearchReaderView`.

### 9.6 Settings (`SettingsView` + `SettingsViewModel`)
Generation (default generator pref; Claude/OpenAI keys with Save/Test/Clear → `KeychainStore`, cheap `max_tokens:1` validation); Web search (Google key + cx); Appearance (UI language `@AppStorage`, applied at `RootView` via locale + layoutDirection); About (version, author).

### 9.7 Research (`ResearchFlowView` + `ResearchConfigViewModel`)
**Config** (`ResearchConfigView`: glass cards — topic `TextEditor` + suggestions, language, length mode+value, tone) → **Generating** (`ResearchGeneratingView`: pulsing mascot + shimmering skeleton "writing" lines + status) → **Reader** (`ResearchReaderView`: styled title/heading/subheading/body/quote, per-section RTL, Export PDF / Copy). `ResearchCard` for Library/Home.

---

## 10. Networking & Security
- **`KeychainStore`** — Security framework; keys `claude`, `openAI`, `googleKey`, `googleCX`; `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`. Never UserDefaults/hardcoded.
- **`APIClient`** — async `postJSON`/`getJSON`, typed `APIError` (http/transport), 30–60s timeouts.
- **`ClaudeGenerator`/`OpenAIGenerator`/`GoogleSearchClient`** — map HTTP 401/403 → `.missingAPIKey`. Claude system prompt is prompt-cached.
- ATS: only HTTPS to api.anthropic.com / api.openai.com / googleapis.com (no Info.plist exception needed).

## 11. Export Subsystem
| Exporter | Output | Technique |
|---|---|---|
| `PDFExporter` | deck → 1920×1080 vector PDF | `CGContext` PDF + `ImageRenderer.render` per slide (sharp text) |
| `PPTXExporter` | deck → `.pptx` | image-per-slide + hand-built minimal OOXML parts, zipped via `ZIPArchive` |
| `ZIPArchive` | — | native store-method ZIP writer + CRC32 (iOS has no public ZIP writer) |
| `ResearchPDFExporter` | research → A4 multi-page PDF | `UIGraphicsBeginPDFContextToData` + `NSAttributedString` + **CoreText `CTFramesetter` pagination**, RTL per section |
| `ShareSheet` | — | `UIActivityViewController` wrapper; `SharePayload` (Identifiable URL) |

## 12. Persistence & Sync (`SlydeePersistence`)
`makeContainer()` tries **CloudKit `.automatic`** → falls back to local store → last-resort in-memory (never crash on launch). `mainContext.undoManager` enabled (editor undo/redo). `Slydee.entitlements` declares iCloud CloudKit container `iCloud.com.slydee.app` + `aps-environment`.
**Lesson recorded:** CloudKit aborted launch when `Deck.slides`/`Slide.blocks` were non-optional — CloudKit requires all relationships optional. Fixed by making to-many optional + safe accessors. Any future `@Model` must follow §4.4.

## 13. Localization & RTL
`Localizable.xcstrings` (source `en`, full `ar`); region `ar` registered. `L` = typed `LocalizedStringKey` namespace. `AppLanguage` (english/arabic/mixed) → layout direction + font. `LanguageDetector` (Unicode-range Arabic check) drives **per-block / per-section** language so a single slide or document mixes Arabic (RTL) and English (LTR) correctly. UI language switch applied app-wide in `RootView`.

## 14. Concurrency Model
Swift 6 language mode + complete checking. `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`. UI/VMs MainActor; the entire data/value/utility/AI/networking layer is `nonisolated` + `Sendable`/`Codable`. Generators are `Sendable` and run off-actor; results are `Sendable` value types; `DeckBuilder`/exporters hop back to `@MainActor` for `ModelContext`/`ImageRenderer`. Status tickers/generation use structured `Task` with cancellation.

## 15. Known Limitations & Risks
1. No device/TestFlight validation across any phase.
2. AI is **mock** — real generators not wired (Foundation Models/Claude/OpenAI scaffolding exists but unproven at runtime).
3. PPTX/PDF correctness in PowerPoint/Keynote unverified.
4. CloudKit sync unverified (needs founder's Apple Developer iCloud container + a device); app degrades to local so it can't crash.
5. Widgets / Live Activities absent (need new extension targets — risky pbxproj surgery, deferred pending confirmation).
6. Research feature uncommitted.
7. DOCX import out of scope (PDF/txt only).

## 16. Roadmap & Extension Points
| Next | Where |
|---|---|
| Wire real deck AI | `GeneratorFactory` (swap Mock for Foundation/Claude/OpenAI chain — scaffolding already present) |
| Wire real research AI | `ResearchGeneratorFactory` (documented TODO, same shape) |
| Device test → TestFlight | the standing Phase-1 gate; needed before further scope per founder's own discipline |
| CloudKit go-live | provision `iCloud.com.slydee.app` in Apple Developer, test on device |
| Widgets / Live Activities | requires adding Xcode app-extension targets + App Group (confirm before pbxproj edits) |
| IBM Plex Sans Arabic | drop TTFs in resources, set `SlydeeFont.arabicCustomFamily` |
| Commit Research | `git add` + Conventional Commit + push |

Founder context: AiQo (separate app) awaiting App Store re-review; university time constraint — favor shipping/validation over new scope.

## 17. Appendix — File Reference (79 Swift files)

**App**: `SlydeeApp` (@main), `RootView` (tabs + locale).
**Models**: `Deck`, `Slide`, `Block`, `BlockContent`, `BlockAnimation`, `Enums`, `SlideBackground`, `Template`, `AppSettings`, `WebResult`, `StickerCatalog`, `ResearchDocument`, `ResearchModels`.
**Core/AI**: `AIGenerator`, `GeneratorFactory`, `FallbackGenerator`, `FoundationModelGenerator`, `ClaudeGenerator`, `OpenAIGenerator`, `MockGenerator`, `SlideJSONSchema`, `PromptBuilder`, `DeckBuilder`, `DeckJSONParser`, `ResearchGenerator`, `MockResearchGenerator`, `ResearchGeneratorFactory`.
**Core/DesignSystem**: `Colors`, `Typography`, `Spacing`, `Components/{SlydeeButton, SlydeeCard, GlassCard, MascotView}`.
**Core/Export**: `PDFExporter`, `PPTXExporter`, `ZIPArchive`, `ResearchPDFExporter`, `ShareSheet`.
**Core/Extensions**: `JSONCoding`. **Core/Input**: `SourceTextExtractor`, `ImageTextRecognizer`.
**Core/Localization**: `AppLanguage`, `L`, `LanguageDetector`. **Core/Networking**: `APIClient`, `KeychainStore`, `GoogleSearchClient`. **Core/Persistence**: `SlydeePersistence`.
**Features**: Home `{HomeView, DeckCard}`; Create `{CreateView, CreateViewModel, InputStep, ConfigureStep, GenerateStep, SearchInputView}`; Editor `{EditorView, EditorViewModel, EditableSlideCanvas, TextInspectorView, StickerPickerView, ChartInspectorView, AnimationInspectorView, SlideInspectorView}`; Preview `{DeckPreviewView, SlideCanvas}`; Library `{LibraryView}`; Settings `{SettingsView, SettingsViewModel}`; Templates `{TemplatePreview}`; Research `{ResearchFlowView, ResearchConfigViewModel, ResearchConfigView, ResearchGeneratingView, ResearchReaderView, ResearchCard}`.

## 18. Universal AI JSON Schema (decks)
```json
{ "title": "string", "subtitle": "string", "language": "english|arabic|mixed",
  "slides": [ { "layout": "titleOnly|titleContent|twoColumn|quote|sectionDivider",
    "language": "english|arabic", "title": "string", "subtitle": "string?",
    "bullets": ["string"], "body": "string?", "speakerNotes": "string" } ] }
```

---
*End of Master Blueprint. Regenerate after major changes to keep it the source of truth.*
