# iOS & SwiftUI Code Review Checklist

Combined checklist from Bornfight iOS guidelines and modern SwiftUI best practices.

## 🛠 General & Process
- [ ] **Merge Conflicts:** Are there any merge conflicts?
- [ ] **Xcode Warnings:** Are there any new Xcode warnings introduced?
- [ ] **Coding Guidelines:** Is the code consistent with the project's style?

## 🏗 Architecture & SwiftUI Structure
- [ ] **Separation of Concerns:** 
    - [ ] Logic extracted from Views into ViewModels or Models.
    - [ ] Views are not modified directly in View Models.
- [ ] **View Composition:** 
    - [ ] Complex views extracted into smaller, reusable subviews.
    - [ ] Functions have a single purpose.
- [ ] **Modifier Ordering:** Are modifiers applied in the correct order (e.g., padding before background)?
- [ ] **Dependency Injection:** Singletons avoided in favor of passing dependencies.

## 💾 State Management
- [ ] **Property Wrappers:** 
    - [ ] `@State` used for local private **value types** (Bool, Int, String) only.
    - [ ] **Senior Audit:** `@State` is NEVER used for reference types (classes). Use `@StateObject` or the iOS 17 `@Observable` macro.
    - [ ] `@Binding` used for two-way data flow from parents.
    - [ ] `@StateObject` used for initial creation; `@ObservedObject` for passed-in objects.
- [ ] **Modern Observation:** Adoption of iOS 17+ `@Observable` where applicable.
- [ ] **Data Flow:** Is state owned by the correct view and passed down appropriately?

## 🧵 Concurrency & Async
- [ ] **Concurrency Safety:** 
    - [ ] All network calls or long-running tasks are inside `Task` blocks.
    - [ ] **Actor Safety:** UI-updating properties and methods are correctly marked with `@MainActor`.
    - [ ] Async/Await used instead of completion handlers where possible.
- [ ] **Memory Management:** `[weak self]` used in closures to avoid retain cycles.
- [ ] **Async Workflows:** Prefer `.task` modifier over `onAppear + Task`.

## 🚀 Performance & Optimization
- [ ] **View Updates:** Minimize unnecessary body re-computations.
- [ ] **Computation Placement:** **Senior Check:** Heavy computations (sorting, filtering, formatting) are NOT inside SwiftUI `body`. Move them to a background thread or a memoized computed property in the ViewModel.
- [ ] **Lazy Containers:** Proper usage of `LazyVStack`/`LazyHStack` for long lists.
- [ ] **Identity:** `ForEach` uses stable, unique identifiers.

## 💻 Code Quality & Style
- [ ] **Naming Conventions:** Clear, consistent, self-documenting. Booleans start with `is`, `can`, `should`.
- [ ] **Encapsulation:** Use `private` or `private(set)` where possible.
- [ ] **Constants:** Magic numbers extracted into constants (e.g., `DrawerConstants`).
- [ ] **Safety:** Force unwrapping (`!`) avoided. `guard` used for early returns.
- [ ] **Cleanliness:** No commented-out code or unused variables/imports.

## ♿ Accessibility & Localization
- [ ] **Accessibility:** Presence of descriptive labels, hints, and traits for VoiceOver.
- [ ] **Dynamic Type:** Layouts scale correctly with system font size changes.
- [ ] **Localization:** User-facing strings moved to `Localizable.strings`.

## 🔒 Security & Error Handling
- [ ] **Error Handling:** All error cases handled/logged.
- [ ] **Security:** No secrets or sensitive data logged or stored in plain text.
