# Change Log

All notable changes to this helm chart will be documented in this file.

## :heavy_check_mark: 20220527

### Added
- Support for Edge nodes.
- Support for `nodeSelector`.
- Support for `tolerations`.
- Allow to add additional labels to the hub, edge, firefox and chrome nodes.
- Fix queue component name (#1290)

### Changed
- Update image tag to 4.1.4-20220427

### Removed
- Opera nodes

## :heavy_check_mark: 0.2.0

### Added
- `CHANGELOG.md`

### Changed
- Added `global` block to be able to specify component's image tag globally.
- DSHM's volume size customizable.
- Service type and service annotations are now customizable.

### Fixed
- Services won't be created if nodes are disabled.

## :heavy_check_mark: 0.1.0

### Added
- Selenium grid components separated.
- Selenium Hub server.
- Chrome, Opera and Firefox nodes.
