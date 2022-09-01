# Change Log

All notable changes to this helm chart will be documented in this file.

## :heavy_check_mark: 0.9.0

### Added
- Add lifecycle preStop hook & startupProbe, fix port number

## :heavy_check_mark: 0.8.1

### Changed
- Update image tag to 4.4.0-20220831

## :heavy_check_mark: 0.8.0

### Added
- Added support of loadBalancerIP for hub and router services

## :heavy_check_mark: 0.7.0

### Added
- Added ability to specify image pull secrets

## :heavy_check_mark: 0.6.2

### Added
- Pod PriorityClasses

## :heavy_check_mark: 0.6.1

### Changed
- Update image tag to 4.3.0-20220706

## :heavy_check_mark: 0.6.0

### Added
- Added ability to set hostAliases on browser node deployments

## :heavy_check_mark: 0.5.0

### Added
- Added ability to mount arbitrary volumes into browser nodes

## :heavy_check_mark: 0.4.2

### Changed
- Update image tag to 4.3.0-20220624

## :heavy_check_mark: 0.4.1

### Changed
- Update image tag to 4.2.1-20220608

## :heavy_check_mark: 0.4.0

### Added
- Expose the Hub or the Router by default with ingress resource.

### Changed
- Set the default serviceType of the Hub and the Router to ClusterIP

## :heavy_check_mark: 0.3.1

### Added
- Helm charts repo to GitHub Pages - https://www.selenium.dev/docker-selenium

### Changed
- Update image tag to 4.2.1-20220531

## :heavy_check_mark: 0.3.0

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
