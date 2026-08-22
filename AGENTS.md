# AGENTS.md — Universal Flutter Project Guide

> This file is the source of truth for AI coding agents and human contributors working on any Flutter project.
> Read this file before planning, editing, refactoring, reviewing, or generating code.

If a repository also contains a more specific adjacent guide for that project or feature, follow the local guide first and then update this universal guide only if a reusable rule should be generalized.

---

## 0. Purpose

This guide defines a reusable, production-grade standard for Flutter projects.

It is designed to work across many app types:

- consumer mobile apps
- dashboards
- e-commerce apps
- chat apps
- map and tracking apps
- VPN/client apps
- admin panels
- offline-first apps
- multiplayer or real-time apps
- animation-heavy apps
- lightweight games
- desktop Flutter apps
- Flutter web apps

The goal is to keep every project:

- modular
- maintainable
- scalable
- testable
- performant
- readable
- consistent
- localization-ready
- friendly to low-end devices
- easy for future agents and developers to understand

---

## 1. Core Principles

### 1.1 Non-Negotiable Rules

- Do not put business logic inside widgets.
- Do not create huge files with mixed responsibilities.
- Do not hardcode user-facing strings.
- Do not hardcode colors, text styles, spacing, radius, or animation durations inside feature widgets.
- Do not duplicate route strings across the app.
- Do not expose raw technical errors directly to users.
- Do not create dumping-ground files like `utils.dart`, `helpers.dart`, or `common.dart` unless the content is truly generic and cohesive.
- Do not rewrite unrelated features while completing a scoped task.
- Keep code readable before making it clever.
- **Every animation must be optimized and must not cause unnecessary rebuilds.** Cache animation objects, use cheap transform/opacity animations, wrap animated zones with `RepaintBoundary`, and never create tweens or curves inside `build()`.

### 1.2 Project Quality Goals

Every feature should be:

- easy to locate by folder responsibility
- easy to test without rendering the full app
- easy to refactor safely
- visually consistent with the design system
- optimized enough for real devices
- clear about loading, error, empty, and success states
- ready for localization and accessibility

---

## 2. Recommended Project Structure

Use a feature-first architecture with shared app infrastructure in `core/`.

```txt
lib/
  main.dart
  app/
    app.dart
    router/
      app_router.dart
      route_names.dart
      route_paths.dart
      route_guards.dart
      route_transitions.dart

  core/
    constants/
    errors/
      app_exception.dart
      app_error_mapper.dart
      failure.dart
    extensions/
    l10n/
      app_localizations.dart
      app_texts.dart
      locale_controller.dart
    network/
      api_client.dart
      network_info.dart
      interceptors/
    settings/
      app_settings.dart
      app_settings_repository.dart
      app_settings_provider.dart
    storage/
      local_storage.dart
      secure_storage.dart
    theme/
      app_colors.dart
      app_typography.dart
      app_spacing.dart
      app_radius.dart
      app_motion.dart
      app_shadows.dart
      app_theme.dart
    utils/
    widgets/
      app_button.dart
      app_text_field.dart
      app_card.dart
      app_scaffold.dart
      app_modal.dart
      app_toast.dart
      app_dialogs.dart
      app_loading.dart
      app_empty_state.dart
      app_error_state.dart

  features/
    feature_name/
      domain/
        entities/
        value_objects/
        repositories/
        services/
      application/
        use_cases/
        controllers/
        coordinators/
        providers/
      infrastructure/
        data_sources/
        dto/
        repositories/
      presentation/
        screens/
        providers/
        widgets/
        models/

  shared/
    models/
    widgets/
    services/

test/
  core/
  features/
    feature_name/
      domain/
      application/
      presentation/
```

### 2.1 Folder Responsibility

Place code by responsibility, not convenience.

| Code type | Location |
|---|---|
| Pure business rules | `features/<feature>/domain/` |
| Entities and value objects | `features/<feature>/domain/entities/` or `value_objects/` |
| Repository contracts | `features/<feature>/domain/repositories/` |
| Use cases and workflows | `features/<feature>/application/` |
| Feature state controllers | `features/<feature>/application/` or `presentation/providers/` depending on responsibility |
| API/local implementations | `features/<feature>/infrastructure/` |
| DTOs and mappers | `features/<feature>/infrastructure/dto/` |
| Screens | `features/<feature>/presentation/screens/` |
| Feature-specific widgets | `features/<feature>/presentation/widgets/` |
| Reusable app-wide widgets | `core/widgets/` |
| Theme tokens | `core/theme/` |
| Routing | `app/router/` or `core/router/` |
| Localization | `core/l10n/` |
| Error mapping | `core/errors/` |
| Settings and persistence | `core/settings/`, `core/storage/` |

---

## 3. Architecture Rules

### 3.1 Layering

Use clear boundaries:

```txt
Presentation -> Application -> Domain
Presentation -> Application -> Infrastructure
Infrastructure implements Domain contracts
```

Presentation may read state and trigger actions. It must not own business rules.

Application coordinates workflows. It may call repositories, services, and domain rules.

Domain contains pure business knowledge. It should be as Flutter-independent as possible.

Infrastructure talks to APIs, databases, local storage, sockets, platform channels, and external SDKs.

### 3.2 Dependency Direction

- Domain must not import Flutter UI packages.
- Domain must not depend on infrastructure.
- Infrastructure may depend on domain contracts.
- Presentation may depend on application state/controllers.
- Widgets should not directly call raw API clients, Hive boxes, SQLite databases, or platform channels.

### 3.3 When to Create a Use Case

Create a use case when:

- the action has business meaning
- the workflow has validation or branching
- the same behavior is used from multiple screens
- the operation is worth testing independently
- orchestration would otherwise bloat a controller or widget

Examples:

```txt
LoginUseCase
CreateOrderUseCase
SyncMessagesUseCase
UpdateProfileUseCase
StartSessionUseCase
SubmitFeedbackUseCase
```

### 3.4 When Not to Over-Abstract

Do not create unnecessary layers for tiny prototypes or simple screens.

A simple feature can start with:

```txt
feature/
  application/
  presentation/
```

Then grow into domain/infrastructure when real complexity appears.

---

## 4. State Management

### 4.1 Default Recommendation

Use one primary state management approach per project.

Recommended options:

- Riverpod for scalable Flutter apps
- Bloc/Cubit for event/state-heavy teams
- ValueNotifier/ChangeNotifier for small isolated local state

Do not mix multiple global state systems unless the project already requires it.

### 4.2 Riverpod Rules

If using Riverpod:

- Keep providers close to the feature when feature-specific.
- Keep app-wide providers in `core/di/` or `core/providers/`.
- Prefer `ref.watch(provider.select(...))` for narrow rebuilds.
- Use `ref.read(...)` for actions and non-reactive access.
- Do not watch a huge state object in a root widget if only one field is needed.
- Split widgets so each watches the smallest possible state.
- Keep async states explicit: loading, data, empty, error.

Example:

```dart
final userName = ref.watch(
  profileProvider.select((state) => state.user.name),
);
```

### 4.3 Controller Rules

Controllers should:

- expose clear public actions
- hide implementation details
- avoid UI widget references
- avoid direct `BuildContext` unless unavoidable
- handle async cancellation or stale responses where necessary
- not become god classes

Bad:

```dart
class AppController {
  // auth + cart + orders + profile + navigation + dialogs
}
```

Good:

```txt
AuthController
CartController
OrderController
ProfileController
```

### 4.4 UI State vs Business State

Separate:

- business state: user, order, session, game, subscription, chat messages
- UI state: selected tab, expanded panel, text field focus, animation flag, modal visibility

Feature controllers may coordinate both, but business rules should remain separate.

### 4.5 Never Rebuild the Whole Screen for Small State Changes

Bad:

```dart
setState(() {
  unreadCount++;
});
```

If this lives at screen level, it may rebuild the whole screen.

Better:

```dart
ValueListenableBuilder<int>(
  valueListenable: unreadCountNotifier,
  builder: (_, count, __) => Badge(count: count),
)
```

### 4.6 Select Only Needed State

If using Provider, Riverpod, Bloc, Redux, or similar tools, subscribe only to the slice of state needed by the widget.

Rules:

- Avoid watching a huge global state object from large widgets.
- Use selectors where available.
- Separate visual state from business state.
- Keep ephemeral animation state local.
- Batch related state updates.

Principle:

```md
Changing a button loading state should not rebuild the full page.
Changing one list item should not rebuild the whole list.
Changing one socket event should not rebuild all visible panels.
```

### 4.7 Avoid Heavy Work in build

Never perform expensive operations inside `build`.

Avoid in `build`:

- Sorting.
- Filtering large lists.
- JSON parsing.
- Date formatting for many items.
- Regex processing.
- Image processing.
- Creating animation tweens.
- Creating controllers.
- Network calls.

Bad:

```dart
@override
Widget build(BuildContext context) {
  final sortedItems = items..sort((a, b) => a.name.compareTo(b.name));
  return ItemList(items: sortedItems);
}
```

Better:

```dart
final sortedItems = [...items]..sort(
  (a, b) => a.name.compareTo(b.name),
);
```

Do this before the widget build phase, for example in state management, a controller, a cached derived getter, or another precomputed layer.

---

## 5. Routing and Navigation

### 5.1 Centralized Routing

All routes must be centralized.

Suggested files:

```txt
lib/app/router/app_router.dart
lib/app/router/route_names.dart
lib/app/router/route_paths.dart
lib/app/router/route_guards.dart
lib/app/router/route_transitions.dart
```

Rules:

- Do not push raw route strings from widgets.
- Use route names and paths constants.
- Pass lightweight route data only.
- Prefer IDs over full objects.
- Keep route guards centralized.
- Keep transition logic centralized.

Bad:

```dart
context.push('/product/details/${product.id}');
```

Good:

```dart
context.pushNamed(
  RouteNames.productDetails,
  pathParameters: {'id': product.id},
);
```

### 5.2 Route Data

Pass:

- IDs
- small enums
- query parameters
- flags

Avoid passing:

- large models
- controllers
- repositories
- mutable state
- UI widgets

### 5.3 Navigation Side Effects

Navigation side effects should live in:

- route guards
- coordinators
- screen controllers
- explicit action handlers

Avoid random navigation inside large `build()` branches.

### 5.4 Route Transitions and Modals

- Keep route transitions lightweight.
- Avoid blur-heavy modal backgrounds.
- Avoid `AnimatedSwitcher` around large trees.
- Avoid full-screen opacity layers over complex backgrounds.
- Use separate `RepaintBoundary`s for modal chrome and scrollable body.
- Keep only the active tab in the tree when modal height should match content.
- Avoid `IndexedStack` for large tab forms unless preserving state is required.

Recommended modal structure:

```dart
Column(
  children: const [
    RepaintBoundary(child: ModalHeader()),
    Expanded(
      child: RepaintBoundary(child: ModalBody()),
    ),
    RepaintBoundary(child: ModalActions()),
  ],
)
```

---

## 6. Theme and Design System

### 6.1 Centralized Theme Tokens

Create a design system before building many screens.

Suggested files:

```txt
lib/core/theme/app_colors.dart
lib/core/theme/app_typography.dart
lib/core/theme/app_spacing.dart
lib/core/theme/app_radius.dart
lib/core/theme/app_motion.dart
lib/core/theme/app_shadows.dart
lib/core/theme/app_theme.dart
```

### 6.2 Rules

- No hardcoded colors in feature widgets.
- No random Material default colors unless intentionally part of the design system.
- No magic spacing values scattered everywhere.
- No hardcoded animation durations inside widgets.
- No one-off button/card/modal styles when shared primitives exist.
- All reusable surfaces must come from shared widgets or theme tokens.

Bad:

```dart
Container(
  padding: const EdgeInsets.all(17),
  color: const Color(0xff123456),
)
```

Good:

```dart
Container(
  padding: AppSpacing.allMd,
  decoration: BoxDecoration(
    color: AppColors.surface,
    borderRadius: AppRadius.lg,
  ),
)
```

### 6.3 Motion Tokens

All animation durations and curves should be centralized.

```dart
class AppDurations {
  static const fast = Duration(milliseconds: 150);
  static const normal = Duration(milliseconds: 250);
  static const slow = Duration(milliseconds: 400);
}

class AppCurves {
  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubic;
}
```

Use tokens instead of magic values.

### 6.4 Shared Primitives

Create shared primitives for common UI:

```txt
AppButton
AppTextField
AppCard
AppScaffold
AppModal
AppToast
AppDialog
AppIconButton
AppLoading
AppEmptyState
AppErrorState
AppBadge
AppDivider
AppAvatar
```

Do not duplicate the same style in multiple screens.

---

## 7. Localization, RTL, and Text

### 7.1 Localization Rules

- No hardcoded user-facing strings in widgets.
- All labels, errors, titles, buttons, empty states, and messages must come from localization.
- Keep copy short and clear.
- Format numbers, dates, prices, and units centrally.
- Support RTL/LTR layout properly.

### 7.2 Directionality

If the app supports Persian, Arabic, Hebrew, Urdu, or other RTL languages:

- test every screen in RTL
- avoid manual left/right assumptions
- use `start` and `end` instead of `left` and `right` when possible
- use `EdgeInsetsDirectional`
- use `AlignmentDirectional`
- make icons mirror only when meaningful

Good:

```dart
padding: const EdgeInsetsDirectional.only(start: 16, end: 12)
alignment: AlignmentDirectional.centerStart
```

### 7.3 Typography

- Use centralized text styles.
- Use font families through theme.
- Do not hardcode fonts inside random widgets.
- Ensure small text remains readable on low-end and small devices.
- Avoid excessive letter spacing for Persian/Arabic text.

---

## 8. Error Handling

### 8.1 Error Model

Use clear error types.

```txt
AppException
Failure
ValidationFailure
NetworkFailure
AuthFailure
PermissionFailure
StorageFailure
UnknownFailure
```

### 8.2 User-Facing Mapping

Map technical errors before showing them.

```dart
final message = AppErrorMapper.mapAnyError(error, l10n);
AppToast.error(context, message);
```

Rules:

- Do not show raw exception text to normal users.
- Do not leak stack traces in production UI.
- Log diagnostics separately.
- Use reusable toast/dialog/error-state widgets.
- Keep error messages actionable.

### 8.3 Loading, Empty, Error, Success

Every async screen should define:

- loading state
- empty state
- error state
- retry behavior
- success/data state

Do not leave screens blank while loading or after failure.

---

## 9. Networking and APIs

### 9.1 API Client

Centralize HTTP configuration:

```txt
base URL
headers
timeouts
auth token handling
refresh token handling
logging in debug only
error mapping
retry policy when appropriate
```

### 9.2 Rules

- Do not call raw HTTP clients directly from widgets.
- Keep DTOs separate from domain entities.
- Map DTOs to domain models.
- Keep request/response logging centralized in shared infrastructure such as `core/logging/` or `core/network/interceptors/`, and enable verbose logging only in debug builds.
- Mask sensitive headers and payload fields such as tokens, cookies, passwords, and secrets before writing logs.
- Handle cancellation or stale responses for search/autocomplete.
- Avoid duplicate refresh-token calls when many requests fail at once.
- Keep interceptors small and focused.

### 9.3 DTO Mapping

```dart
class UserDto {
  const UserDto({required this.id, required this.name});

  final String id;
  final String name;

  User toDomain() => User(id: id, name: name);
}
```

Domain models should not depend on API response shape.

---

## 10. Persistence and Local Storage

### 10.1 Storage Types

Use the right storage for the right data.

| Data | Recommended storage |
|---|---|
| theme/language/settings | Hive, SharedPreferences, Isar, SQLite |
| auth tokens | secure storage |
| cached API data | database/cache layer |
| large files | filesystem/cache manager |
| sensitive data | encrypted/secure storage |

### 10.2 Rules

- UI must not directly access storage boxes.
- Storage must be behind repositories or services.
- Do not store sensitive data unnecessarily.
- Plan migrations for schema changes.
- Keep cached data invalidation explicit.

---

## 11. Real-Time, Socket, and Event-Driven Apps

Use this section for chat, tracking, games, trading, delivery, VPN/client status, and multiplayer apps.

### 11.1 Event Rules

- Incoming events should be parsed into typed events.
- Do not let socket callbacks mutate UI directly.
- Keep socket/realtime logging in the service layer rather than scattering `print` or `debugPrint` across widgets and controllers.
- Queue or debounce high-frequency updates.
- Keep server state and visual state separate when animations are needed.
- Handle reconnect, stale data, duplicate events, and out-of-order events.

### 11.2 Suggested Flow

```txt
Socket/API event
 -> DTO/parser
 -> domain/application event
 -> controller/state update
 -> UI rebuilds only affected widgets
```

### 11.3 Event Queue

Use a queue when events need visual sequencing.

Examples:

- chat message animations
- game actions
- order status transitions
- courier movement updates
- notification banners
- onboarding steps

Rules:

- Only one major visual event should present at a time.
- Events should be serializable when practical.
- Event objects must not carry widgets.
- Presentation decides how to animate events.
- Domain decides what happened.

### 11.4 Network, Socket, and Realtime Performance

Realtime data can destroy UI performance when every message updates the visible screen immediately.

Rules:

- Queue socket events that trigger visual changes.
- Batch frequent updates.
- Throttle high-frequency events like location, typing, progress, or telemetry updates.
- Separate raw network state from UI state.
- Avoid rebuilding the whole screen when one item changes.
- Keep optimistic UI updates small and reversible.
- Deduplicate repeated server events.

Strategy:

```md
Socket event received -> validate/deduplicate -> update domain state -> enqueue visual update -> rebuild only affected widget
```

For location or tracking apps:

- Smooth marker movement with animation interpolation.
- Do not recreate the whole map on every update.
- Update only marker/source data.
- Throttle updates if events arrive faster than the screen can display them.

---

## 12. Performance Standards

### 12.1 Core Performance Goal

Every Flutter project should be designed around predictable frame cost.

Target:

- Keep the **UI Thread** and **Raster Thread** under `16ms` for stable 60 FPS.
- Avoid repeated frame spikes above `24ms` during scrolling, animation, navigation, or modal transitions.
- Test real performance in **Profile** or **Release** mode, never only in Debug mode.
- Avoid visual effects whose cost changes unpredictably across devices.

Recommended command:

```bash
flutter run --profile
```

Use Flutter DevTools to inspect:

- UI Thread time.
- Raster Thread time.
- Jank frames.
- Rebuild counts.
- Shader compilation spikes.
- Memory growth.
- Image cache usage.
- Network-triggered rebuilds.

### 12.2 Rebuild Rules

- Use `const` constructors aggressively.
- Split large widgets into smaller widgets.
- Watch the smallest possible state.
- Avoid expensive work in `build()`.
- Do not sort, filter, parse JSON, or process images inside `build()`.
- Memoize derived values when needed.
- Use stable keys for dynamic collections.

Bad:

```dart
@override
Widget build(BuildContext context) {
  final sorted = users..sort((a, b) => a.name.compareTo(b.name));
  return UserList(users: sorted);
}
```

Good:

```dart
final sortedUsers = ref.watch(sortedUsersProvider);
return UserList(users: sortedUsers);
```

### 12.3 Rendering Rules

Avoid heavy rendering patterns:

- large animated shadows
- large blur areas
- repeated `Opacity` around complex trees
- unnecessary `ClipRRect`
- complex `ShaderMask`
- huge SVGs in lists or animated areas
- oversized images decoded at runtime
- constantly running background animations

Prefer:

- direct color alpha instead of `Opacity` widgets
- gradients instead of blur-heavy glows
- `ShapeDecoration` instead of clipping when possible
- `RepaintBoundary` around isolated animated/static zones
- optimized WebP/PNG assets
- lazy builders for lists

#### Shadows and Glows

Avoid expensive shadows in moving, scrolling, or frequently rebuilt widgets.

Rules:

- Avoid `BoxShadow` with `blurRadius > 15` on animated or scrollable widgets.
- Prefer `blurRadius <= 12` for cards, sheets, panels, and list items.
- For glow effects, prefer `RadialGradient` or pre-rendered image glow instead of heavy shadow blur.
- Avoid animating shadow blur, spread, or color every frame.
- Keep `TextShadow.blurRadius` below `3` for large headings.

Bad:

```dart
BoxShadow(
  blurRadius: 40,
  spreadRadius: 8,
)
```

Better:

```dart
BoxDecoration(
  gradient: RadialGradient(
    colors: [
      Colors.amber.withValues(alpha: 0.18),
      Colors.transparent,
    ],
  ),
)
```

#### Opacity and saveLayer

The `Opacity` widget can trigger expensive offscreen rendering when used around complex widget trees.

Rules:

- Avoid wrapping large widgets with `Opacity`.
- Apply alpha directly to colors when possible.
- Use `FadeTransition` for fade animations.
- Avoid opacity over images, maps, videos, large SVGs, lists, and full-screen layouts.

Bad:

```dart
Opacity(
  opacity: 0.5,
  child: ComplexCard(),
)
```

Better:

```dart
Container(
  color: Colors.black.withValues(alpha: 0.5),
  child: const ComplexCard(),
)
```

#### Clipping and Rounded Corners

Clipping can be expensive, especially when repeated many times.

Rules:

- Avoid unnecessary `ClipRRect` in lists, grids, and animated widgets.
- Prefer `ShapeDecoration` with `RoundedRectangleBorder` when you only need rounded visuals.
- Use clipping only when content must truly be cut.
- Avoid clipping images during animations unless necessary.

Better:

```dart
DecoratedBox(
  decoration: ShapeDecoration(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    color: Colors.white,
  ),
)
```

#### BackdropFilter and Blur

Blur is one of the most expensive visual effects.

Rules:

- Avoid `BackdropFilter` behind scrollable or animated content.
- Never use multiple full-screen blur layers.
- Prefer fake glass effects with gradients, alpha blending, borders, and subtle highlights.
- If blur is required, keep the blurred area small and static.
- Provide a reduced-effect fallback for low-end devices.

Optimized glass-like panel:

```dart
Container(
  decoration: ShapeDecoration(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: Colors.white.withValues(alpha: 0.18),
      ),
    ),
    gradient: LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.16),
        Colors.white.withValues(alpha: 0.07),
      ],
    ),
  ),
)
```

#### ShaderMask and Color Filters

Rules:

- Avoid `ShaderMask` on icons or text used in lists, animations, and frequently rebuilt areas.
- For gradient text, use `Paint()..shader` in `TextStyle` only when necessary.
- Avoid applying color filters repeatedly to large images.
- Prefer pre-colored assets for repeated decorative elements.

### 12.4 RepaintBoundary Rules

Use `RepaintBoundary` around:

- expensive static backgrounds
- isolated animated widgets
- large scrollable content
- canvas/custom painter sections
- frequently moving elements that should not repaint siblings
- maps behind overlays
- charts and graphs
- game boards or interactive canvases
- complex cards in a dashboard

Do not add `RepaintBoundary` everywhere blindly. Measure when possible.

### 12.5 Lists and Scroll

- Use `ListView.builder`, `GridView.builder`, or slivers for large collections.
- Avoid `Column(children: items.map(...).toList())` for large lists.
- Avoid nested scrollables unless required.
- Use stable item heights when possible.
- Avoid complex animated widgets inside long lists.
- Use pagination or virtualization for very large data.
- Avoid large shadows, blur, complex SVGs, and animated widgets inside list items.
- Use keys carefully; unstable keys can cause unnecessary rebuilds.

#### Scroll Physics

For graphically heavy screens:

```dart
ListView.builder(
  physics: const ClampingScrollPhysics(),
  itemBuilder: ...,
)
```

Rules:

- Prefer `ClampingScrollPhysics` on heavy Android screens.
- Avoid expensive animated headers in scrollable content.
- Avoid layout jumps caused by late-loading images.
- Use placeholders with fixed dimensions.

#### Pagination and Infinite Scroll

Rules:

- Do not load very large datasets at once.
- Paginate API results.
- Cache loaded pages.
- Avoid calling pagination requests multiple times during fast scroll.
- Debounce search and filter input.
- Show stable skeletons that do not shift layout.

### 12.6 Images and Assets

- Compress large images before adding them.
- Prefer WebP for decorative images when suitable.
- Decode near display size using `cacheWidth`/`cacheHeight` when possible.
- Precache important images before critical screens.
- Avoid `Image.network` for decorative assets that should be bundled.
- Use placeholders that do not cause layout jumps.

Example:

```dart
Image.asset(
  'assets/images/banner.webp',
  cacheWidth: 720,
)
```

#### Asset Format

Rules:

- Use `WebP` for decorative images and illustrations where appropriate.
- Use `PNG` only when lossless quality or specific transparency is required.
- Avoid shipping oversized images.
- Compress all large assets before adding them to the project.
- Prefer multiple asset sizes for important images.

#### Decode Near Display Size

Good:

```dart
Image.asset(
  'assets/images/banner.webp',
  cacheWidth: 720,
)
```

Rules:

- Use `cacheWidth` and `cacheHeight` when the displayed size is known.
- Avoid decoding 4K images for small thumbnails.
- Avoid full-resolution remote images when thumbnails are enough.

#### Remote Images

Rules:

- Cache remote images.
- Use placeholders with fixed width and height.
- Avoid reloading images during route changes.
- Avoid loading too many images at the same time.
- Use thumbnails for lists and full images only in detail screens.

### 12.7 SVG Rules

SVGs can be expensive.

- Keep path count low.
- Avoid SVG filters, masks, embedded shadows, and huge gradients.
- Prefer raster assets for repeated decorative icons.
- Give SVGs fixed width and height.
- Avoid complex SVGs inside animations and large lists.
- Avoid animated SVGs inside scrollable content.
- Prefer simple monochrome SVGs for icons.
- Remove unused metadata from SVG files.

Good:

```dart
SvgPicture.asset(
  'assets/icons/home.svg',
  width: 24,
  height: 24,
)
```

For repeated decorative icons, consider a reusable wrapper that can switch between SVG and raster assets based on performance mode.

### 12.8 Animation Rules

Prefer cheap animations:

- `FadeTransition`
- `ScaleTransition`
- `SlideTransition`
- `RotationTransition`
- `Transform.translate`
- `AnimatedSwitcher` for small content

Avoid animating:

- blur
- shadows
- gradients
- clipping masks
- large layout changes
- complex SVGs

Cache animation objects in `initState` when using controllers.

Bad:

```dart
@override
Widget build(BuildContext context) {
  final animation = Tween<double>(begin: 0, end: 1).animate(controller);
  return FadeTransition(opacity: animation, child: child);
}
```

Good:

```dart
late final Animation<double> fadeAnimation;

@override
void initState() {
  super.initState();
  fadeAnimation = CurvedAnimation(
    parent: controller,
    curve: AppCurves.standard,
  );
}
```

#### Animation Optimization Mandate

Every animation in the codebase must:

- Be created with `initState`-cached tweens and curves (never recreated in `build`).
- Use `Transform` widgets (translate, rotate, scale) for GPU-accelerated movement rather than layout-changing properties.
- Be wrapped in `RepaintBoundary` when the animated widget is expensive or has siblings that should not repaint with it.
- Avoid triggering parent rebuilds during animation frames.
- Use centralized motion tokens (`AppDurations`, `AppCurves`) instead of magic values.
- Pause or cancel when the route or screen is not visible to avoid wasting frame budget.
- Be tested in Profile mode to verify no jank is introduced.
- Defer animation start to the next frame when the animation runs alongside a heavy initial layout — use `WidgetsBinding.instance.addPostFrameCallback((_) => controller.forward())` instead of starting in `initState`.

#### Route Visibility and Offscreen Animations

Animations should not continue ticking when the route is hidden behind another page, dialog, or modal unless that behavior is explicitly desired.

Rules:

- Pause `AnimationController`s when a route is no longer visible.
- Use `TickerMode` to mute entire animated subtrees when appropriate.
- Stop repeating ambient effects behind modals, sheets, and pushed routes.
- Keep route observer lifecycle centralized instead of duplicating subscribe/unsubscribe boilerplate in many widgets.

This matters most for:

- loaders
- decorative background loops
- orbiting icons
- particle or glow effects
- game overlays
- dashboard hero animations

#### Queue Complex Visual Events

For apps with multiple visual events, such as games, chat apps, order tracking, dashboards, notification feeds, and socket-driven apps:

- Queue incoming events.
- Animate one major visual event at a time.
- Avoid applying multiple UI-changing events in the same frame.
- Separate server state from visual timeline state.

Example:

```dart
class UiEventQueue {
  final Queue<Future<void> Function()> _queue = Queue();
  bool _running = false;

  void add(Future<void> Function() task) {
    _queue.add(task);
    _run();
  }

  Future<void> _run() async {
    if (_running) return;
    _running = true;

    while (_queue.isNotEmpty) {
      final task = _queue.removeFirst();
      await task();
    }

    _running = false;
  }
}
```

### 12.9 Low-End Mode

Every visual-heavy app should support a lower-cost mode.

Suggested settings:

```dart
class PerformanceSettings {
  const PerformanceSettings({
    this.reduceMotion = false,
    this.disableGlow = false,
    this.lowShadow = true,
    this.useRasterIcons = true,
    this.staticBackground = false,
    this.disableBlur = false,
    this.simplifyBackgrounds = false,
  });

  final bool reduceMotion;
  final bool disableGlow;
  final bool lowShadow;
  final bool useRasterIcons;
  final bool staticBackground;
  final bool disableBlur;
  final bool simplifyBackgrounds;
}
```

#### Premium Mode

Use on stronger devices:

- Rich backgrounds.
- Controlled gradients.
- Moderate shadows.
- Full transition set.
- More decorative motion.

#### Balanced Mode

Recommended default:

- Conservative shadows.
- No expensive animated backgrounds.
- Optimized SVG or raster icons.
- Moderate animations.
- Limited glow.

#### Low-End Mode

Use for weak devices:

- Minimal glow.
- Minimal shadows.
- Reduced motion.
- Static backgrounds.
- No blur.
- Raster decorative assets.
- Fewer particles or ornaments.
- Lower image decode sizes.
- Shorten animation durations.

---

## 13. Responsive Layout

### 13.1 General Rules

- Use `SafeArea` where needed.
- Use `LayoutBuilder` for complex responsive layouts.
- Test small Android phones.
- Test large phones and tablets.
- Avoid fixed heights unless justified.
- Avoid vertical overflow.
- Avoid assuming English text length.
- Avoid assuming LTR.

### 13.2 Screen Types

Scrollable content screens:

- forms
- product lists
- settings
- article/detail pages
- dashboards

Fixed viewport screens:

- camera
- maps
- games
- media players
- live tracking
- immersive experiences

For fixed viewport screens:

- avoid `SingleChildScrollView` as the main layout
- use `Stack` and overlays
- keep critical information visible
- adapt sizes based on available constraints

### 13.3 Modals and Bottom Sheets

- Keep headers/actions separated from scrollable body.
- Avoid huge animated headers in scrollable modals.
- Use max height constraints.
- Make keyboard behavior explicit.
- Do not let bottom sheets overflow on small screens.

---

## 14. Clean Code Standards

### 14.1 File Size

Split files when:

- a screen mixes layout, navigation, side effects, and business logic
- a widget file has many private UI sections
- a controller has unrelated branches
- a file becomes difficult to scan
- repeated UI can become a named component

Suggested pattern:

```txt
profile_screen.dart
widgets/
  profile_header.dart
  profile_stats_card.dart
  profile_action_list.dart
  profile_logout_button.dart
providers/
  profile_controller.dart
```

### 14.2 Naming

Use names by responsibility.

Good:

```txt
AuthController
OrderRepository
ProductDetailsScreen
UserAvatar
CheckoutSummaryCard
SocketConnectionService
LocationPermissionController
```

Avoid:

```txt
Helper
Utils
Manager2
NewWidget
CustomContainer
TestScreen
```

### 14.3 Function Design

Functions should:

- do one thing
- have clear names
- avoid deep nesting
- return early for invalid states
- avoid hidden side effects
- be testable when they contain logic

### 14.4 Comments

Use comments to explain why, not what.

Good:

```dart
// Keep this delay in presentation only so domain tests stay deterministic.
await Future<void>.delayed(AppDurations.shortPause);
```

Bad:

```dart
// This increments i by 1.
i++;
```

---

## 15. Testing Standards

### 15.1 Test Types

Use the right test type:

| Test type | Use for |
|---|---|
| Unit test | rules, mappers, validators, use cases |
| Widget test | UI states, forms, empty/error/loading views |
| Golden test | visual regression for important components |
| Integration test | critical user flows |
| Manual profile test | performance-sensitive screens |

### 15.2 Minimum Test Expectations

Add or update tests when changing:

- business rules
- auth/session logic
- payment/checkout flows
- navigation guards
- socket/event sequencing
- storage migrations
- validators
- data mappers
- offline sync
- app-critical UI states

### 15.3 Common Commands

```bash
flutter analyze
flutter test
flutter test test/features/profile/
flutter run --profile
```

If time is limited, run targeted checks for impacted files.

### 15.4 Performance Testing Strategy

A screen is not production-ready until it is tested on real devices.

Test builds:

```bash
flutter run --profile
flutter build apk --release
flutter build appbundle --release
```

Acceptance criteria:

```md
- [ ] 95% of frames stay under 16ms on target devices.
- [ ] No repeated Raster Thread spikes above 24ms during normal usage.
- [ ] No visible jank during navigation, scrolling, modal opening, or main animations.
- [ ] Memory does not continuously grow after 10 minutes of usage.
- [ ] Images are not decoded at much larger sizes than displayed.
- [ ] No expensive work is performed inside build methods.
- [ ] Large lists are lazy-rendered.
- [ ] Socket or realtime events are throttled, batched, or queued.
- [ ] Reduced-motion or low-end mode exists when the UI is visually heavy.
```

Device matrix:

```md
- [ ] Low-end Android device: 2GB/3GB RAM.
- [ ] Mid-range Android device.
- [ ] Older iPhone if iOS is supported.
- [ ] 60Hz display.
- [ ] 90Hz/120Hz display if relevant.
- [ ] Low-end web browser device if Flutter Web is supported.
```

---

## 16. Accessibility

Every production app should consider accessibility.

Rules:

- Use semantic labels for icon-only buttons.
- Ensure touch targets are large enough.
- Respect text scaling where practical.
- Keep contrast readable.
- Do not communicate important information with color only.
- Avoid excessive motion or support reduced motion.
- Make loading and error states understandable.

Example:

```dart
IconButton(
  tooltip: l10n.close,
  onPressed: onClose,
  icon: const Icon(Icons.close),
)
```

---

## 17. Platform-Specific Rules

### 17.1 Android

- Test on real low-end and mid-range devices.
- Watch shader compilation and raster thread spikes.
- Handle back button behavior intentionally.
- Request permissions only when needed.
- Watch Raster Thread carefully.
- Avoid heavy blur, shadows, SVGs, and oversized images.
- Check performance on 60Hz and high-refresh devices.

### 17.2 iOS

- Respect safe areas.
- Test notch and dynamic island devices.
- Handle permission copy carefully.
- Keep scrolling and transitions platform-appropriate.
- Test older iPhones, not only new devices.
- Watch memory pressure and startup time.
- Avoid unnecessary platform channel calls during animations.

### 17.3 Web

- Avoid huge initial bundles.
- Use responsive layouts.
- Avoid mobile-only assumptions.
- Handle browser refresh and deep links.
- Optimize images and fonts.
- Use lazy loading where possible.
- Compress images aggressively.
- Avoid expensive full-screen filters.
- Test on low-end laptops and mobile browsers.

### 17.4 Desktop

- Support resizable windows.
- Support keyboard/mouse interactions.
- Avoid mobile-only navigation patterns.
- Consider hover/focus states.
- Watch window resizing performance.
- Avoid rebuilding complex layouts on every size change.
- Be careful with large scrollable tables and high-resolution images.

---

## 18. Security and Privacy

- Store tokens in secure storage.
- Do not log sensitive data.
- Do not expose secrets in source code.
- Keep API keys out of the client when they must be private.
- Validate user input.
- Sanitize displayed remote content when needed.
- Use HTTPS for network requests.
- Keep permission requests minimal and explain why they are needed.

---

## 19. Project-Type Specific Rules

### 19.1 E-commerce and Ordering Apps

- Use lazy lists for stores/products/orders.
- Cache product thumbnails.
- Avoid layout jumps in product cards.
- Debounce search and filters.
- Do not rebuild the full list when one item updates.
- Use pagination for large result sets.

### 19.2 Chat Apps

- Use lazy reverse lists.
- Keep message bubbles lightweight.
- Cache avatars.
- Avoid complex SVGs in every message.
- Batch typing/read-receipt updates.
- Do not rebuild all messages when one message status changes.

### 19.3 Map and Tracking Apps

- Do not recreate the map widget unnecessarily.
- Update markers/sources instead of rebuilding the whole map.
- Throttle location updates.
- Cluster large marker sets.
- Keep custom markers small and pre-rendered.

### 19.4 Dashboard/Admin Apps

- Virtualize or paginate large tables.
- Avoid rendering thousands of rows at once.
- Memoize filtered/sorted data.
- Keep charts isolated with `RepaintBoundary`.
- Debounce filters.

### 19.5 Animation-Heavy Apps

- Use a central animation timeline when multiple animations need coordination.
- Queue visual events.
- Avoid animating layout-heavy properties.
- Provide reduced motion.
- Preload animation assets.

### 19.6 Games and Interactive Apps

- Queue gameplay events.
- Animate one major action at a time.
- Separate game state from visual animation state.
- Preload critical assets and sounds.
- Avoid rebuilding the full scene for one object change.
- Use `RepaintBoundary` around static scene layers.

### 19.7 VPN, Network, or Utility Apps

- Keep connection status updates isolated.
- Do not rebuild the whole home screen on every traffic/stat update.
- Throttle speed meter updates.
- Move heavy parsing or config generation outside `build`.
- Avoid blocking UI during process or network operations.

---

## 20. CustomPainter and Canvas Drawing

`CustomPainter` can be very fast, but only when repaints are controlled.

Rules:

- Implement `shouldRepaint` precisely.
- Avoid drawing hundreds of complex paths every frame.
- Avoid repeated `quadraticBezierTo` and complex ornamental paths in persistent backgrounds.
- Prefer simple lines, circles, dots, and low-point shapes for decorative backgrounds.
- Cache paths when possible.
- Separate animated canvas layers from static canvas layers.
- Wrap static painters with `RepaintBoundary`.

Good:

```dart
@override
bool shouldRepaint(covariant BackgroundPainter oldDelegate) {
  return oldDelegate.seed != seed || oldDelegate.color != color;
}
```

Bad:

```dart
@override
bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
```

---

## 21. Forms and Input-Heavy Screens

Forms can become slow when every keystroke rebuilds the whole page.

Rules:

- Keep field state local when possible.
- Avoid validating the entire form on every keystroke.
- Debounce remote validation.
- Avoid rebuilding all fields when one field changes.
- Avoid expensive formatters in `build`.
- Keep dropdown lists lazy if they are large.
- Avoid heavy SVG icons in every input field.

For search fields:

```dart
Timer? _debounce;

void onSearchChanged(String value) {
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 350), () {
    search(value);
  });
}
```

---

## 22. Audio and Haptics

Audio and haptics should never load at the moment of interaction.

Rules:

- Preload short sound effects.
- Keep audio files compressed and short.
- Avoid playing too many effects in the same frame.
- Avoid blocking UI while loading audio.
- Respect reduced-motion and low-end modes by reducing nonessential feedback.

---

## 23. Memory Management

Low-end devices often fail because of memory pressure, not just frame time.

Rules:

- Watch memory growth during long sessions.
- Dispose controllers, focus nodes, streams, timers, and animation controllers.
- Avoid keeping large lists, images, or decoded data alive unnecessarily.
- Limit image cache when the app has many images.
- Avoid memory leaks from socket subscriptions.

Example:

```dart
@override
void dispose() {
  controller.dispose();
  focusNode.dispose();
  subscription.cancel();
  timer?.cancel();
  super.dispose();
}
```

Optional image cache tuning:

```dart
void configureImageCache() {
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 100;
  imageCache.maximumSizeBytes = 80 << 20; // 80 MB
}
```

Tune these numbers based on real device testing.

---

## 24. Asset Preloading

Preload assets that are needed immediately after a transition or during critical interactions.

Useful for:

- App splash to home transition.
- Game screens.
- Product detail images.
- Map markers.
- Onboarding illustrations.
- Heavy icons.
- Audio effects.

Example:

```dart
Future<void> preloadCriticalAssets(BuildContext context) async {
  await Future.wait([
    precacheImage(
      const AssetImage('assets/images/background.webp'),
      context,
    ),
    precacheImage(
      const AssetImage('assets/images/avatar_placeholder.webp'),
      context,
    ),
  ]);
}
```

Rules:

- Preload only critical assets.
- Do not preload the whole app if it increases startup time too much.
- Use staged preloading after first frame when possible.
- For SVG preloading, render `SvgPicture.asset` inside a widget tree that actually paints (not `Offstage`). `flutter_svg` caches parsed SVG data at paint time, so `Offstage(offstage: true)` will not warm the SVG cache — use `Opacity(opacity: 0.001)` or position the widget off-screen instead.

---

## 25. Shader Compilation, Skia, and Impeller

First-run animation jank can happen because shaders are compiled on demand.

Rules:

- Test animation-heavy screens in Profile and Release.
- Compare behavior with the renderer used by your Flutter version and target platform.
- Watch for first-run jank in route transitions, gradients, shadows, and effects.
- Warm up critical screens or animations if needed.
- When building warmup widgets for shader pre-compilation, do NOT nest them inside `Offstage(offstage: true)` — it skips painting entirely, so `CustomPainter.paint()` never runs and shaders never compile. Use `Opacity(opacity: 0.001)` or position the widget off-screen with negative coordinates (e.g. `Positioned(left: -10000)`) to force actual GPU compilation without visible rendering.
- To pre-warm `flutter_svg` assets, include `SvgPicture.asset` in the same warmup widget tree so SVGs are parsed and cached before first use.

Useful commands:

```bash
flutter run --profile
```

For projects that still rely on SkSL warmup workflows, test with the Flutter version used in the project before making it part of CI.

---

## 26. Agent Workflow

When an AI coding agent receives a task:

### 26.1 First

- Read this `AGENTS.md`.
- Inspect the related files before editing.
- Identify the correct layer for the change.
- Reuse existing primitives before creating new ones.
- Do not assume files exist.

### 26.2 Before Large Changes

Provide a short implementation plan including:

- files to create
- files to edit
- files to remove or refactor
- risk areas
- acceptance criteria

### 26.3 During Implementation

- Keep changes scoped.
- Prefer incremental, testable changes.
- Follow existing project style when it is good.
- If existing style conflicts with this guide, improve carefully.
- Do not rewrite unrelated code.
- Keep localization, theme, routing, and errors centralized.

### 26.4 After Implementation

Report:

- what changed
- why it changed
- files touched
- tests/checks run
- assumptions
- remaining risks or incomplete areas

Do not claim tests passed if they were not run.

---

## 27. Prompting Standards for Coding Agents

Use issue-style prompts.

Good prompt:

```txt
Read AGENTS.md.
Refactor the checkout screen to use shared AppButton, AppTextField, and AppErrorState.
Move validation into a controller/use case.
No hardcoded strings, colors, or route paths.
Acceptance criteria:
- flutter analyze passes
- checkout loading/error/success states work
- no business logic remains in the widget
```

Bad prompt:

```txt
Make this page better.
```

For UI tasks, include:

- desired feeling
- layout constraints
- performance constraints
- components to reuse
- what not to do
- acceptance criteria

For performance tasks, include:

- target screen
- known jank areas
- allowed visual tradeoffs
- metrics to check

For architecture tasks, include:

- current pain point
- desired layer separation
- files to inspect
- compatibility requirements

---

## 28. Common Task Templates

### 28.1 Build a New Feature

```txt
Read AGENTS.md.
Create a feature-first module for <feature>.
Use domain/application/infrastructure/presentation only where needed.
No business logic in widgets.
Use centralized routing, theme, localization, and error handling.
Add tests for business rules and mappers.
```

### 28.2 Refactor a Screen

```txt
Read AGENTS.md.
Refactor <screen> into smaller widgets and a controller if needed.
Keep behavior unchanged.
Remove hardcoded colors, strings, spacing, and durations.
Reduce rebuild scope.
Run flutter analyze.
```

### 28.3 Performance Pass

```txt
Read AGENTS.md.
Audit <screen/feature> for unnecessary rebuilds, heavy rendering, oversized images, complex SVGs, missing const, expensive build work, and missing RepaintBoundary.
Fix only performance and architecture issues.
Preserve visual design unless a change is required for performance.
```

### 28.4 Add Localization

```txt
Read AGENTS.md.
Move all user-facing text in <feature> to the localization system.
Respect RTL/LTR.
Do not hardcode labels, errors, empty states, or button text.
```

### 28.5 Add API Integration

```txt
Read AGENTS.md.
Add API integration for <feature>.
Create DTOs, mapper, repository implementation, and application use case/controller.
Do not call API client from widgets.
Map technical errors through AppErrorMapper.
```

### 28.6 Add Real-Time Event Handling

```txt
Read AGENTS.md.
Implement typed real-time events for <feature>.
Do not mutate UI directly from socket callbacks.
Parse events, update application state, and rebuild only affected widgets.
Handle reconnect, duplicates, stale events, and out-of-order events where applicable.
```

### 28.7 Add an Animation

```txt
Read AGENTS.md.
Add an animation for <feature>.
Use GPU-accelerated Transform widgets (translate, rotate, scale).
Cache tweens and curves in initState.
Wrap the animated widget in RepaintBoundary.
Use centralized motion tokens (AppDurations, AppCurves).
Never create animation objects inside build().
Verify no unnecessary rebuilds are introduced.
Run flutter analyze.
Test in Profile mode.
```

### 28.8 Add API Integration with Code Generation

```txt
Read AGENTS.md.
Add API integration for <feature> using <json_serializable/freezed>.
Create DTO classes with <json_serializable/freezed> annotations.
Map DTOs to domain models.
Create repository implementation.
Wire up API client.
Run build_runner and flutter analyze.
```

---

## 29. Definition of Done

A task is done only when all relevant items are true:

- correct folder and layer placement
- no business logic inside widgets
- no hardcoded user-facing strings
- no hardcoded colors, typography, spacing, radius, or animation durations
- no duplicated route strings
- no raw technical errors shown to users
- reusable primitives are used where appropriate
- rebuild scope remains reasonable
- async states are handled clearly
- layout works on small and large screens
- RTL/LTR is respected when localization exists
- accessibility basics are covered
- new logic is testable
- tests are added or updated for meaningful logic changes
- analyzer passes or remaining issues are honestly reported
- code is understandable by the next developer or agent
- **every animation is optimized: tweens/curves cached, GPU-accelerated transforms used, no unnecessary rebuilds, RepaintBoundary applied where needed**
- profiled in Profile or Release mode if the change introduces new animations or visual effects

---

## 30. Anti-Patterns to Avoid

- giant widgets with business logic mixed in
- controllers that manage unrelated features
- direct storage/API calls from UI
- raw route strings in widgets
- one-off button/card/dialog styling
- duplicated error handling
- hardcoded Persian/English text in widgets
- hardcoded colors and magic spacing values
- complex SVGs in lists and animations
- expensive calculations inside `build()`
- nested ternaries and deeply nested conditionals
- generic dumping-ground files
- rewriting unrelated files during a focused task
- claiming validation was done without running checks
- creating animation tweens/curves inside `build()` instead of caching them
- animating layout, blur, shadow, or clip properties instead of using transforms and opacity
- wrapping large widget subtrees with `Opacity` instead of using color alpha
- leaving animation controllers running when the route is not visible

---

## 31. Universal Production Checklist

```md
## Rendering
- [ ] No large BoxShadow on moving or scrollable widgets.
- [ ] No unnecessary Opacity around complex trees.
- [ ] No unnecessary ClipRRect in repeated widgets.
- [ ] No full-screen blur on low-end mode.
- [ ] Static background and dynamic content are separated.

## Rebuilds
- [ ] const is used wherever possible.
- [ ] Large screens are split into small widgets.
- [ ] State subscriptions are scoped to the smallest needed widget.
- [ ] One small state change does not rebuild the entire screen.
- [ ] Heavy calculations are not inside build.

## Lists and Data
- [ ] Large lists use builders or slivers.
- [ ] Pagination exists for large remote data.
- [ ] Search/filter input is debounced.
- [ ] Sorting/filtering is memoized or done outside build.

## Assets
- [ ] Large images are compressed.
- [ ] Images decode near display size.
- [ ] Complex SVGs are not used repeatedly.
- [ ] Critical assets are preloaded.
- [ ] Audio effects are preloaded if used.

## Animations
- [ ] Tween and CurvedAnimation objects are not created inside build.
- [ ] Cheap transform/opacity animations are preferred.
- [ ] Blur, shadow, and layout-heavy animations are avoided.
- [ ] Complex visual events are queued.
- [ ] Reduced-motion mode exists for heavy UIs.
- [ ] Every animated widget is wrapped in or isolated by RepaintBoundary.
- [ ] Animation controllers are paused or disposed when the route is not visible.

## Memory
- [ ] Controllers, streams, timers, and subscriptions are disposed.
- [ ] Memory is tested during long sessions.
- [ ] Image cache is monitored and tuned when needed.

## Testing
- [ ] Tested in Profile mode.
- [ ] Tested in Release mode.
- [ ] Tested on a real low-end device.
- [ ] DevTools frame chart has been inspected.
- [ ] No repeated jank during core user flows.
```

---

## 32. Final Reminder

The most important architecture rule:

```txt
Business logic decides what happens.
Application/controller logic coordinates when it happens.
Presentation renders it clearly, consistently, and efficiently.
```

The most important UI rule:

```txt
Every screen must make the current state, available actions, loading, errors, and results obvious to the user.
```

The most important performance rule:

```txt
Avoid unnecessary rebuilds, expensive paint work, oversized assets, and heavy animation effects before they become visible jank.
```

The most important animation rule:

```txt
Every animation must be optimized. Cache tweens in initState, use GPU-accelerated transforms, wrap with RepaintBoundary, and never cause parent rebuilds.
```

The most important clean code rule:

```txt
Write code that the next developer or AI agent can safely understand, test, and change.
```

A performant Flutter app is not a visually poor app. It is an app where every expensive visual decision is intentional.

Prefer:

- Gradients instead of heavy blur.
- Shape drawing instead of clipping masks.
- Transform animations instead of layout animations.
- Scoped state instead of global rebuilds.
- Lazy lists instead of huge widget trees.
- Optimized assets instead of oversized files.
- Queued visual events instead of chaotic simultaneous updates.
- Real-device testing instead of assumptions.
