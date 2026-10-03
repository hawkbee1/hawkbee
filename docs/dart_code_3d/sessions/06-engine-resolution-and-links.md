# Session 06 — Engine part 2: reference resolution and links

**Branch:** `dc3d/s06-engine-links` · **Depends on:** 05.
**Skills:** `vgv-ai-flutter-plugin:testing`.
**Read:** `architecture.md` §5.1 (stages 5–6, 8) and §5.2 (resolver strategy). Read
the session 05 log first.

## Goal

Add **links**: calls (main feature), plus imports, implements, mixins and
extendsExternal according to the rules. Resolution goes through the
`ReferenceResolver` **strategy interface**, so the future `fullResolution` mode can
plug in without changing anything else.

## 1. Strategy interface (`lib/src/resolve/`)

```dart
/// One place in the code that refers to something callable.
class ReferenceSite { /* enclosing node id, library path, AST node (MethodInvocation,
   FunctionExpressionInvocation, InstanceCreationExpression, PropertyAccess for getters,
   PrefixedIdentifier, SuperConstructorInvocation, RedirectingConstructorInvocation),
   local scope snapshot */ }

sealed class ResolvedReference {}
class ResolvedToNode extends ResolvedReference { final String nodeId; final LinkResolution resolution; } // exact | byName
class ResolvedAmbiguous extends ResolvedReference { final List<String> candidateIds; }
class ResolvedExternal extends ResolvedReference { final String packageName; }
class Unresolved extends ResolvedReference { final String reason; }

abstract interface class ReferenceResolver {
  ResolvedReference resolve(ReferenceSite site, ResolverContext context);
}
```

`ResolverContext` gives read access to the `SymbolTable` and the library namespaces
from session 05. **Only** `DeclaredTypeResolver` lives in the MVP. Add a doc comment
on the interface that names the future `AnalyzerResolver` and points to `future.md`.

## 2. `DeclaredTypeResolver`

Walk each function/method body with a `RecursiveAstVisitor`, keeping a **scope stack**
of local variables → static type name (when known). Resolve, in this order:

| Site | Rule |
|---|---|
| `foo()` (no target) | local function → method of the enclosing class or its project superclasses → top-level function visible in the library namespace (own declarations + imports, with prefixes, `show`/`hide`, transitive exports) |
| `Foo()` / `Foo.named()` / `const Foo()` | constructor of class `Foo` visible in the namespace (link to the constructor node if it is a sphere, else to the class) |
| `Foo.staticMember()` | static member of visible class `Foo` |
| `prefix.foo()` | through the import with that prefix |
| `this.x()`, `super.x()` | enclosing class / superclass chain |
| `a.x()` where `a` is a parameter, field, top-level variable, or local with a **declared type** `T` | member `x` of `T` (follow project superclasses, mixins; `T?` → `T`; generic `T<…>` → `T`) |
| `final a = Foo(...)`, `var a = Foo.named(...)` | infer `a : Foo` |
| `a.b.c()` | resolve left to right while types are known (field/getter declared types) |
| cascades `a..x()..y()` | target type of `a` |
| `T` is external (imported from `package:p`) | `ResolvedExternal('p')` |
| receiver type unknown | `links.ambiguous_calls`: `skip` → `Unresolved`; `uniqueName` → if exactly one project member/function named `x` → `ResolvedToNode(byName)` else `Unresolved`; `all` → `ResolvedAmbiguous(all candidates)` |

Calls inside a class body but outside a method (field initializers) are attributed
to the class node. Calls in top-level variable initializers are attributed to a
pseudo-source: skip them in the MVP and count them in the stats.

## 3. Link building

- `ResolvedToNode` → `CodeLink(call, resolution)`, from the **enclosing node** (method
  or function sphere; fall back to the nearest ancestor sphere if the member kind is
  disabled) to the target.
- `ResolvedAmbiguous` → one `ambiguous` link per candidate.
- `ResolvedExternal` → link to `pkg:<p>` with resolution `external` (if
  `nodes.external_packages`).
- Merge duplicates (same from, to, kind) by summing `count`. No self-links.
- `links.imports`: one link per (importing **file's top-level nodes** cluster
  representative → imported library). Simplest valid choice: from each top-level node
  of the importing file to each top-level node of the imported file is far too many,
  so link **file representative = the largest top-level node of the file** to the
  imported file's largest top-level node, or to `pkg:<p>`. Document this in code.
- `links.implements` / `links.mixins`: class → interface/mixin (project node, or
  `pkg:` / ghost when external).
- `extendsExternal`: when `nodes.ghost_parents == false` (intent recorded in session 05).

## 4. Annotators hook

Add `abstract interface class GraphAnnotator { CodeGraph annotate(CodeGraph graph); }`
and run the list given to the engine (empty by default) as the last stage. Test it with
a fake annotator.

## Tests (100% coverage)

Extend the fixtures with `expected.json` **links**. New fixtures:

| Fixture | Covers |
|---|---|
| `calls_basic` | every row of the resolution table above |
| `calls_ambiguous` | two classes with `save()`, a `dynamic`/untyped receiver: test all 3 `links.ambiguous_calls` values |
| `calls_external` | calls on `http.Client`, `Bloc.add`, `print` (`dart:core`, only with `nodes.dart_sdk`) |
| `vgv_feature` | a small VGV-style feature (repository + cubit + page) that looks like real app code |
| `links_toggles` | imports/implements/mixins on and off |

Smoke test on the flutter_scene submodule: record in the session log the link counts
per kind and resolution, plus the **share of `exact` vs `byName` vs unresolved call
sites**. These numbers measure the quality of parse-only mode.

## Acceptance criteria

- [ ] Fixtures pass with exact expected links.
- [ ] No code outside `lib/src/resolve/` depends on `DeclaredTypeResolver` directly (only on the interface).
- [ ] Resolution quality numbers in the session log.
- [ ] Analyze/format clean, 100% coverage, still compiles to JS.

## Session log

_(to be filled by the agent)_
