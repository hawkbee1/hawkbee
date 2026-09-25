# hawkbee

Dart/Flutter monorepo managed with [Melos](https://melos.invertase.dev) and Dart pub workspaces.

## Layout

- `apps/` – applications
- `packages/` – shared packages

Add each new package path to the `workspace:` list in the root `pubspec.yaml`
and add `resolution: workspace` to that package's `pubspec.yaml`.

## Getting started

```sh
dart pub get
dart run melos bootstrap
```

## Scripts

```sh
dart run melos run analyze
dart run melos run format
dart run melos run test
```
