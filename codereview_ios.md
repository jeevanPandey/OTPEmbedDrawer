# iOS Code Review Checklist

Based on the Bornfight iOS Code Review guidelines, here is a structured checklist for your pull requests.

## 🛠 General & Process
- [ ] **Merge Conflicts:** Are there any merge conflicts? (If yes, resolve before proceeding).
- [ ] **Static Analysis:** Has the static analysis check (e.g., SwiftLint) run and passed?
- [ ] **Xcode Warnings:** Are there any new Xcode warnings introduced by these changes?
- [ ] **Coding Guidelines:** Is the code consistent with the agreed-upon project coding guidelines?

## 🏗 Architecture & Design
- [ ] **Separation of Concerns:** 
    - [ ] Data is not fetched or processed in Presenters or Views.
    - [ ] Views are not modified directly in View Models.
- [ ] **Single Responsibility:** 
    - [ ] Functions have a single purpose.
    - [ ] Classes do not have too many responsibilities (avoid "Massive View Controllers").
- [ ] **Single Source of Truth:** Information is not preserved in multiple places.
- [ ] **Dependency Injection:** Singletons are avoided in favor of dependency injection.
- [ ] **Composition:** Composition with protocols is preferred over inheritance.

## 💻 Code Quality & Style
- [ ] **Naming Conventions:**
    - [ ] Naming is clear, consistent, and self-documenting.
    - [ ] Booleans start with `is`, `can`, `should`, or `will`.
    - [ ] `UpperCamelCase` for types/protocols; `lowerCamelCase` for everything else.
- [ ] **Encapsulation:**
    - [ ] Variables and functions use the most restrictive access level possible (`private`, `private(set) `).
    - [ ] Classes that aren't instantiated are defined as `enums`.
- [ ] **Constants & Magic Numbers:**
    - [ ] Magic numbers are avoided and extracted into constants (ideally within a `struct`).
    - [ ] Static constants (`static let`) are preferred over computed properties for fixed values.
- [ ] **Safety:**
    - [ ] Force unwrapping (`!`) is avoided (should be < 1% of cases).
    - [ ] Early returns (e.g., `guard`) are used to handle optional binding.
- [ ] **Cleanliness:**
    - [ ] No commented-out code.
    - [ ] No unused variables, functions, or imports.
    - [ ] No duplicate code (logic is extracted and reused).
    - [ ] Explicit `self` is avoided unless required (e.g., inside closures).

## 🚀 Performance & Memory
- [ ] **Memory Management:**
    - [ ] Closures use `[weak self]` where appropriate to avoid retain cycles.
    - [ ] Delegates are marked as `weak`.
    - [ ] `unowned` is used correctly and not misused.
- [ ] **Optimization:**
    - [ ] String concatenation uses interpolation `\()` instead of `+`.
    - [ ] `isEmpty` is used instead of `count == 0` or `== nil`.
    - [ ] `!` is used instead of `== false`.
    - [ ] `DateFormatter` is instantiated once and reused.
    - [ ] Cells are reused and images are cached.
    - [ ] Heavy tasks are performed on background threads.

## 🔒 Security & Error Handling
- [ ] **Error Handling:** All error cases are handled (logged, user notified, or safe failure).
- [ ] **Security:**
    - [ ] No passwords or secrets are stored as plain text.
    - [ ] No sensitive data is being logged.

## 📝 Documentation & Localization
- [ ] **Localization:** All user-facing strings are localized.
- [ ] **Logging:** 
    - [ ] Important events are logged with sufficient context (class, function, severity).
    - [ ] Logs are clean and not redundant.
- [ ] **Documentation:**
    - [ ] Public functions and complex logic are documented with comments.
    - [ ] Files contain copyright headers.
    - [ ] The `README` is updated if necessary.
