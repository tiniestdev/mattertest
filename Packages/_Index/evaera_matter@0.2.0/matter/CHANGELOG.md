# Changelog

## [0.2.0] - 2022-06-04
### Added
- Added a second parameter to `Matter.component`, which allows specifying default component data.
- Add `QueryResult:snapshot` to convert a `QueryResult` into an immutable list

### Changed
- `queryChanged` behavior has changed slightly: If an entity's storage was changed multiple times since your system last observed it, the `old` field in the `ChangeRecord` will be the last value your system observed the entity as having for that component, rather than what it was most recently changed from.
- World and Loop types are now exported (#9)
- Matter now uses both `__iter` and `__call` for iteration over `QueryResult`.
- Improved many error messages from World methods, including passing nil values or passing a Component instead of a Component instance.
- Removed dependency on Llama

### Fixed
- System error stack traces are now displayed properly (#12)
- `World:clear()` now correctly resets internal changed storage used by `queryChanged` (#13)

### Removed
- Additional query parameters to `queryChanged` have been removed. `queryChanged` now only takes one argument. If your code used these additional parameters, you can use `World:get(entityId, ComponentName)` to get a component, and use `continue` to skip iteration if it is not present.

## [0.1.2]- 2022-01-06
### Fixed
- Fix Loop sort by priority to sort properly

## [0.1.1] - 2022-01-05
### Fixed
- Fix accidental system yield error message in Loop

### Changed
- Accidentally yielding or erroring in a system does not prevent other systems from running.

## [0.1.0] - 2022-01-02

- Initial release