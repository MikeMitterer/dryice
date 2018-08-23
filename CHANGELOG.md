# Change Log for dryice
Lightweight dependency injection framework for Dart.

## [Unreleased](http://github.com/mikemitterer/dryice/compare/v2.0...HEAD)

### Feature
* DryIce is now by default Dart 2.x ready and uses reflectable [98c1ed2](https://github.com/mikemitterer/dryice/commit/98c1ed2701b1dff22f7595e074976ff039d5bd79)

### Fixes
* new bind overwrites the previus one (ModuleContainer) [357dcbd](https://github.com/mikemitterer/dryice/commit/357dcbdbe3b03e00713917183c55da4aa44bcccb)

### Bugs
* Remove weird recursive injectableDeclarations-Function [28a92b5](https://github.com/mikemitterer/dryice/commit/28a92b5c5def71879481db0f968450b8f29c0b75)

### Test
* Removed all references to isInstanceOf, works with latest 'reflectable' version [1ee88c9](https://github.com/mikemitterer/dryice/commit/1ee88c953e37373d636d261afba6a12881c6d0ea)
* Multi-Bind-Test added [03ec3fc](https://github.com/mikemitterer/dryice/commit/03ec3fc3464e5a7ef5bac1a53fca7707ba275197)

## [v2.0](http://github.com/mikemitterer/dryice/compare/v1.8...v2.0) - 2018-05-30

### Feature
* Dart 2.x ready [52cb383](https://github.com/mikemitterer/dryice/commit/52cb383656d38dcfc6df68ff272a1f630ad9d6ea)

### Fixes
* new bind overwrites the previus one (ModuleContainer) [6aedbe8](https://github.com/mikemitterer/dryice/commit/6aedbe82c6eaf9fdda051d36cdf1f51c576abc98)

### Bugs
* Expected wrong return type for ClassMirror#newInstance [a7e1476](https://github.com/mikemitterer/dryice/commit/a7e147646d42d982401c98a99ef7eeef77c592ba)

### Docs
* Info about Dart 2.x [ce4dd03](https://github.com/mikemitterer/dryice/commit/ce4dd03c921a8b40663f04df27aa0b6ad490d657)
* HowTo - test with reflectable [ab784e8](https://github.com/mikemitterer/dryice/commit/ab784e82f40efea0fcf4d44122f030d80af0d80c)


This CHANGELOG.md was generated with [**Changelog for Dart**](https://pub.dartlang.org/packages/changelog)
