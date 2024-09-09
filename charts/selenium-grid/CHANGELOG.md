## :heavy_check_mark: selenium-grid-0.35.2

- Chart is using image tag 4.24.0-20240907
- Chart is tested on Kubernetes versions: v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, v1.31.0, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`9a2afbc0`](http://github.com/seleniumhq/docker-selenium/commit/9a2afbc0290ef031e7458306219f2e8491cefb4d) - chore(deps): update helm release kube-prometheus-stack to v62.6.0 (#2385) :: renovate[bot]
- [`44d92249`](http://github.com/seleniumhq/docker-selenium/commit/44d922495cc686d3fc48605e2b3d9d0836f399a5) - chart(fix): ensure images are pre-pulled and started together in Node (#2387) :: Viet Nguyen Duc
- [`5f42b308`](http://github.com/seleniumhq/docker-selenium/commit/5f42b30815bf32eb170822c09161c03858f46fc7) - update: config basicAuth.enabled is false by default :: Viet Nguyen Duc
- [`c8cd02b8`](http://github.com/seleniumhq/docker-selenium/commit/c8cd02b8c17b530539b38a711bd9f7938f268d4d) - Update chart 0.35.1 changelog [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.35.1

- Chart is using image tag 4.24.0-20240907
- Chart is tested on Kubernetes versions: v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, v1.31.0, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`bcc20e28`](http://github.com/seleniumhq/docker-selenium/commit/bcc20e28ce1301fbe01b06b8e8ace72b0972026a) - Update tag 4.24.0-20240907 in docs and files :: Selenium CI Bot
- [`b53dc3fb`](http://github.com/seleniumhq/docker-selenium/commit/b53dc3fb37815b4310eb7c047ff17dc364a2f839) - update: config supervisord via ENV variables :: Viet Nguyen Duc
- [`44d8bb53`](http://github.com/seleniumhq/docker-selenium/commit/44d8bb532b4501dc0115bd2537cc2fbc1ab40422) - chore(deps): update helm release kube-prometheus-stack to v62.5.0 (#2384) :: renovate[bot]
- [`e4858833`](http://github.com/seleniumhq/docker-selenium/commit/e4858833a5229f8f5b9cc3a41fdd290e7b3a6e13) - chore(deps): update helm release kube-prometheus-stack to v62.4.0 (#2383) :: renovate[bot]
- [`4f2a6e41`](http://github.com/seleniumhq/docker-selenium/commit/4f2a6e41e793e5c17c41ae000f6499bdd311782d) - chart(add): set topologySpreadConstraints for components :: Viet Nguyen Duc
- [`80ebff0f`](http://github.com/seleniumhq/docker-selenium/commit/80ebff0f95b48b3a395719222d32108ec246661b) - build: auto generate table of chart configuration parameter :: Viet Nguyen Duc
- [`53e48937`](http://github.com/seleniumhq/docker-selenium/commit/53e48937779cde056debc60c801a1a747152740e) - Update chart 0.35.0 changelog [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.35.0

- Chart is using image tag 4.24.0-20240830
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, 
- Chart is tested on container runtime Docker versions: 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`c3107507`](http://github.com/seleniumhq/docker-selenium/commit/c31075079cad81cf82e4cc3ffb49a37dab5c3a3a) - Update tag 4.24.0-20240830 in docs and files :: Selenium CI Bot
- [`4c0d9d9a`](http://github.com/seleniumhq/docker-selenium/commit/4c0d9d9a3c3707d456e481f64fbc0a899b9b7552) - chart(rollback): config `ingress.enabled` to create ingress resource only :: Viet Nguyen Duc
- [`4e00e3e3`](http://github.com/seleniumhq/docker-selenium/commit/4e00e3e3d2e529f9f40c2b9988eb5d5c852912a9) - chore(deps): update helm release kube-prometheus-stack to v62.3.1 (#2376) :: renovate[bot]
- [`a7e5c405`](http://github.com/seleniumhq/docker-selenium/commit/a7e5c4052f1fc2531b5f27fc47ecb758c44a0054) - update: Selenium Grid 4.24.0 :: Viet Nguyen Duc
- [`6216a4d9`](http://github.com/seleniumhq/docker-selenium/commit/6216a4d941b5134248bd5353ebcbe87e53f53377) - chart(feat): updateStrategy default RollingUpdate for browsers and Recreate for components :: Viet Nguyen Duc
- [`deb9d308`](http://github.com/seleniumhq/docker-selenium/commit/deb9d3086130a82d6b2a4dea936c79ef82f8780f) - chore(deps): update helm release kube-prometheus-stack to v62.3.0 (#2367) :: renovate[bot]
- [`b4dc1124`](http://github.com/seleniumhq/docker-selenium/commit/b4dc11241f9cb5af781325c92632ec2df3fd0bd5) - chore(deps): update helm release jaeger to v3.2.0 (#2371) :: renovate[bot]
- [`ed2af419`](http://github.com/seleniumhq/docker-selenium/commit/ed2af4193a26cae34d61376dc1d9a76633c36ec0) - update: FFmpeg 7.0.2 and fix video container termination (#2374) :: Viet Nguyen Duc
- [`918765fa`](http://github.com/seleniumhq/docker-selenium/commit/918765fa8d2176da9e82bf57a1ccafab11dc1ccb) - update: graceful shutdown for recording sidecar container in K8s :: Viet Nguyen Duc
- [`d26a433b`](http://github.com/seleniumhq/docker-selenium/commit/d26a433b914f914b0b22b62084772fa138ae93d7) - Update chart changelog [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.34.3

- Chart is using image tag 4.23.1-20240820
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`2adc4a24`](http://github.com/seleniumhq/docker-selenium/commit/2adc4a240686138f156c4865172f17c03cf5a217) - chart(fix): trim trailing slash in sub path :: Viet Nguyen Duc
- [`114d008e`](http://github.com/seleniumhq/docker-selenium/commit/114d008eb0f403f77c2f1ed8a413c28b0e44f421) - Update chart changelog [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.34.2

- Chart is using image tag 4.23.1-20240820
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`ea5e1a7b`](http://github.com/seleniumhq/docker-selenium/commit/ea5e1a7b6e8829d7e176880ec30ed7ac0d886e6a) - build: fix chart release workflow :: Viet Nguyen Duc
- [`c0277249`](http://github.com/seleniumhq/docker-selenium/commit/c02772490f7a99d923d51cb3f3fc02cc949ca58c) - Update tag in docs and files :: Selenium CI Bot
- [`5624122d`](http://github.com/seleniumhq/docker-selenium/commit/5624122d1ea16a1703d77ec3ece8c28c6c5e9c83) - chore(deps): update helm release kube-prometheus-stack to v62 (#2363) :: renovate[bot]
- [`ccb39d52`](http://github.com/seleniumhq/docker-selenium/commit/ccb39d52c124f4c0851dfeea6115247e12401654) - chore(deps): update helm release ingress-nginx to v4.11.2 (#2357) :: renovate[bot]
- [`9106ba14`](http://github.com/seleniumhq/docker-selenium/commit/9106ba146d243e4cf8f26751dbe167fa823ef19c) - chart(fix): Remove alias from sub-chart to prevent render issue in other CD tools :: Viet Nguyen Duc
- [`3bdcb0d4`](http://github.com/seleniumhq/docker-selenium/commit/3bdcb0d4ffc7754e91b6af49739d85db8d14b5d1) - chart(fix): [regression] Able to disable tracing via config key tracing.enabled :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.34.1

- Chart is using image tag 4.23.1-20240813
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.3, 

### Changed
- [`b1fa21cc`](http://github.com/seleniumhq/docker-selenium/commit/b1fa21ccc1be3880491610e8c42c3d3b1e17482b) - chart(update): metadata.namespace to resources :: Viet Nguyen Duc
- [`442ee4ad`](http://github.com/seleniumhq/docker-selenium/commit/442ee4addea500d34e4579db0f0fadc57525efbb) - chore(deps): update helm release keda to v2.15.1 (#2351) :: renovate[bot]
- [`77bc19b9`](http://github.com/seleniumhq/docker-selenium/commit/77bc19b9363152a894c13a395e2c99c889644c02) - chart(release): Update workflow for OCI-based registry publish :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.34.0

- Chart is using image tag 4.23.1-20240812
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.3, 

### Added
- [`b91d3000`](http://github.com/seleniumhq/docker-selenium/commit/b91d30009731304534e14f453b32b2d733266d9a) - add: secure connection for docker compose (#2344) :: Viet Nguyen Duc
- [`68ebfe1a`](http://github.com/seleniumhq/docker-selenium/commit/68ebfe1a39a533dfbc4b3fe37701bcfbff6da005) - feat: add support for structure logs (#2342) :: Ilia Lazebnik
- [`547f97e9`](http://github.com/seleniumhq/docker-selenium/commit/547f97e9ac5e58d44bde8ca8c742e1e61170c4b2) - feat(chart): add support for revisionhistorylimit (#2339) :: Ilia Lazebnik

### Changed
- [`91233c48`](http://github.com/seleniumhq/docker-selenium/commit/91233c48418bf01c6aa2c89b899970762db9580f) - chart(breaking change): update config key to enable ingress (#2349) :: Viet Nguyen Duc
- [`22b2f55d`](http://github.com/seleniumhq/docker-selenium/commit/22b2f55d7f6b5f2dce061eb79bbd5890ea9b0ecf) - chore(deps): update helm release kube-prometheus-stack to v61.8.0 (#2348) :: renovate[bot]
- [`b49b13b4`](http://github.com/seleniumhq/docker-selenium/commit/b49b13b4a6563b9ada7af51d2553b44867872bc4) - update: Tracing is enabled by default (#2347) :: Viet Nguyen Duc
- [`ac606291`](http://github.com/seleniumhq/docker-selenium/commit/ac606291e801860daa8e2bf651e94351acac478f) - chore(deps): update helm release jaeger to v3.1.2 (#2331) :: renovate[bot]
- [`e10ee577`](http://github.com/seleniumhq/docker-selenium/commit/e10ee577f6a4417f5540092284ce5f9b7e3e8c89) - chore(deps): update helm release kube-prometheus-stack to v61.7.2 (#2330) :: renovate[bot]
- [`8bada805`](http://github.com/seleniumhq/docker-selenium/commit/8bada80526a658db7d4568c60da0f7cf91fe1b19) - update: handle graceful shutdown in Node container (#2337) :: Viet Nguyen Duc
- [`7cbc96a0`](http://github.com/seleniumhq/docker-selenium/commit/7cbc96a03d301f812326bef534e6a78754a13d52) - chore(deps): update helm release keda to v2.15.0 (#2335) :: renovate[bot]
- [`1f519c67`](http://github.com/seleniumhq/docker-selenium/commit/1f519c67080f483b11d220a55ef232bafc28c475) - chart(update): update env vars and health check scripts (#2334) :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.33.0

- Chart is using image tag 4.23.0-20240727
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.12, v1.29.7, v1.30.3, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.3, 

### Added
- [`582fb2c7`](http://github.com/seleniumhq/docker-selenium/commit/582fb2c74ea343819ded8011a917ecfa6ce58d97) - add: Env var SE_SUPERVISORD_LOG_LEVEL to set supervisord log level (#2317) :: Viet Nguyen Duc

### Changed
- [`04d1e90e`](http://github.com/seleniumhq/docker-selenium/commit/04d1e90ede4ac05674bfe64f6754c663fab3c797) - chore(deps): update helm release kube-prometheus-stack to v61.4.0 (#2327) :: renovate[bot]
- [`395a401a`](http://github.com/seleniumhq/docker-selenium/commit/395a401a80d3d6241ccbd2e9a940c37c3b14837c) - chart(add): Default ingress annotations for upstream keepalive, or disable HTTP/2 (#2328) :: Viet Nguyen Duc
- [`e15df42f`](http://github.com/seleniumhq/docker-selenium/commit/e15df42f8f1f2f4447288afebf08362c4a16291a) - chart(breaking change): enable TLS and default annotations for ingress (#2326) :: Viet Nguyen Duc
- [`b5d6af37`](http://github.com/seleniumhq/docker-selenium/commit/b5d6af373894bdb12d2e4caac6440cfef5cc7c68) - chart(add): Set pod/container name to node stereotypes (#2323) :: Viet Nguyen Duc
- [`6b2a0153`](http://github.com/seleniumhq/docker-selenium/commit/6b2a0153a83e71ffe160c88d00599b68839f5cda) - chore(deps): update helm release kube-prometheus-stack to v61 (#2292) :: renovate[bot]
- [`5f6db7e2`](http://github.com/seleniumhq/docker-selenium/commit/5f6db7e2615c1818a6e8b92c6787c4bde3f173cc) - chore(deps): update helm release jaeger to v3.1.1 (#2290) :: renovate[bot]
- [`a184528d`](http://github.com/seleniumhq/docker-selenium/commit/a184528d6b55aab7cef604e7313893ae69cc89b2) - chore(deps): update helm release ingress-nginx to v4.11.1 (#2299) :: renovate[bot]
- [`9bd30b0d`](http://github.com/seleniumhq/docker-selenium/commit/9bd30b0db3fa4df18f57226c433bc6b7a9870ce6) - chart(add): proactive to set browser args via container env var (#2308) :: Viet Nguyen Duc
- [`4cc20386`](http://github.com/seleniumhq/docker-selenium/commit/4cc20386419aecffac924860bed56c2938b49537) - chart(breaking change): refactoring config keys to enable secure connection (#2306) :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.32.0

- Chart is using image tag 4.22.0-20240621
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.15, v1.28.11, v1.29.6, v1.30.2, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.2, 

### Added
- [`f2280e98`](http://github.com/seleniumhq/docker-selenium/commit/f2280e985e701d53a1282631b166198752090ebc) - feat(chart): probe checks for Distributor and Router (#2272) :: Viet Nguyen Duc

### Fixed
- [`d5398b75`](http://github.com/seleniumhq/docker-selenium/commit/d5398b75253f13f54da1f31e32cefeda66f5245f) - fix(chart): pod labels and annotations for patch-scaledobjects (#2274) :: Viet Nguyen Duc

### Changed
- [`e16a1677`](http://github.com/seleniumhq/docker-selenium/commit/e16a167723b7908cda64ca97be00750ff6f61c40) - chart: fix config ingress.tls :: Viet Nguyen Duc
- [`904b8ea3`](http://github.com/seleniumhq/docker-selenium/commit/904b8ea36613e1100e09cbe2d5f4bb491181e07a) - chart: not patch KEDA objects if autoscaling disabled :: Viet Nguyen Duc
- [`2f0f2494`](http://github.com/seleniumhq/docker-selenium/commit/2f0f2494d6036370b2336c0ebdf4ed962b2a6d11) - chart: update default chart values :: Viet Nguyen Duc
- [`2c814158`](http://github.com/seleniumhq/docker-selenium/commit/2c8141583da2e7afe86537b3c4178c07dfe36b3f) - chore(deps): update helm release kube-prometheus-stack to v60 (#2280) :: renovate[bot]
- [`148541c5`](http://github.com/seleniumhq/docker-selenium/commit/148541c553995ff42176ff12c07af75bdd4989be) - chore(deps): update helm release jaeger to v3.0.10 (#2253) :: renovate[bot]
- [`714ef8ad`](http://github.com/seleniumhq/docker-selenium/commit/714ef8ad15b0e9e7b8ca1fc5cc696a9447060b3e) - chore(deps): update helm release kube-prometheus-stack to v59 (#2271) :: renovate[bot]

## :heavy_check_mark: selenium-grid-0.31.1

- Chart is using image tag 4.21.0-20240522
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.14, v1.28.10, v1.29.5, v1.30.1, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.0, 

### Changed
- [`5eebd36b`](http://github.com/seleniumhq/docker-selenium/commit/5eebd36b6a6877cc9a0efe91355e1d300d39476e) - [build]: rollback docs update to bump new release :: Viet Nguyen Duc
- [`de9f2c58`](http://github.com/seleniumhq/docker-selenium/commit/de9f2c5812e286b93e4ce94ac01d7b3d0cd9a64a) - [build][test]: Release docker images for aarch64 platform (#2266) :: Viet Nguyen Duc
- [`c082aedf`](http://github.com/seleniumhq/docker-selenium/commit/c082aedf5f9c9fbefaa672d8d2097e9026533778) - Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.31.0

- Chart is using image tag 4.21.0-20240517
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.13, v1.28.9, v1.29.4, v1.30.0, 
- Chart is tested on Helm versions: v3.10.3, v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, 

### Changed
- [`471adc38`](http://github.com/seleniumhq/docker-selenium/commit/471adc388530ed85d0f67871fc19c72debd8ac98) - Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.30.2

- Chart is using image tag 4.20.0-20240505
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.13, v1.28.9, v1.29.4, v1.30.0, 
- Chart is tested on Helm versions: v3.10.3, v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, 

### Fixed
- [`62ea271f`](http://github.com/seleniumhq/docker-selenium/commit/62ea271f36e711365b71442fec16f89ff00509e4) - fix(chart): upload.conf is missing in volumeMounts :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.30.1

- Chart is using image tag 4.20.0-20240505
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.13, v1.28.9, v1.29.4, v1.30.0, 
- Chart is tested on Helm versions: v3.10.3, v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, 

### Added
- [`6d3a8a72`](http://github.com/seleniumhq/docker-selenium/commit/6d3a8a724f7d6909955c263536960eec4e14a4ec) - feat: Video recording with dynamic file name based on metadata in tests (#2249) :: Viet Nguyen Duc

### Fixed
- [`32d0aea8`](http://github.com/seleniumhq/docker-selenium/commit/32d0aea88524f0a7262efba804a4d9dbee555149) - fix(chart): job to cleanup scaled objects run always :: Viet Nguyen Duc
- [`07e13f6c`](http://github.com/seleniumhq/docker-selenium/commit/07e13f6c61ac014271d57d98dfcf1869def06a78) - fix(chart): RBAC settings for job patch finalizers (#2239) :: Viet Nguyen Duc

### Changed
- [`409a46f2`](http://github.com/seleniumhq/docker-selenium/commit/409a46f232c74f55b9b6b9e4f93e15853bf80bfa) - chore(deps): update helm release kube-prometheus-stack to v58.4.0 (#2248) :: renovate[bot]
- [`6e859e0b`](http://github.com/seleniumhq/docker-selenium/commit/6e859e0b95a75798500666a6e56eac3170b651d2) - chore(deps): update helm release jaeger to v3.0.6 (#2246) :: renovate[bot]
- [`8fcc44b0`](http://github.com/seleniumhq/docker-selenium/commit/8fcc44b0b503670e8a3265a69efd983f060d27ad) - chore(deps): update helm release keda to v2.14.2 (#2244) :: renovate[bot]
- [`b0799353`](http://github.com/seleniumhq/docker-selenium/commit/b07993539f78587a30db04680ae46464de06eec1) - update: Rollback FFmpeg v6.1.1 (#2247) :: Viet Nguyen Duc
- [`b279999a`](http://github.com/seleniumhq/docker-selenium/commit/b279999a26e1d50086d382622782a8725edaab23) - chore(deps): update helm release kube-prometheus-stack to v58.3.3 (#2240) :: renovate[bot]
- [`322741e9`](http://github.com/seleniumhq/docker-selenium/commit/322741e9537a7dc6fd8af926cae533b54a813146) - chore(deps): update helm release kube-prometheus-stack to v58.3.0 (#2238) :: renovate[bot]
- [`0762e873`](http://github.com/seleniumhq/docker-selenium/commit/0762e873b583c4ad3241b2311e50b8a95c1d288f) - chore(deps): update helm release kube-prometheus-stack to v58.2.2 (#2211) :: renovate[bot]
- [`4631baa5`](http://github.com/seleniumhq/docker-selenium/commit/4631baa5d27951992bf2565e509d475dafbd499a) - chore(deps): update helm release jaeger to v3.0.4 (#2219) :: renovate[bot]
- [`96550ead`](http://github.com/seleniumhq/docker-selenium/commit/96550eadc93e63f4883c8b3a15069867c919a62e) - chore(deps): update helm release ingress-nginx to v4.10.1 (#2230) :: renovate[bot]
- [`67099bbe`](http://github.com/seleniumhq/docker-selenium/commit/67099bbe1cb000e62bdae3491aed02b09db02179) - chore(deps): update helm release keda to v2.14.1 (#2234) :: renovate[bot]
- [`fe7c16cc`](http://github.com/seleniumhq/docker-selenium/commit/fe7c16cc8d0310283b65f9ef03a96d2e5850a9e5) - chore(deps): update helm release keda to v2.14.0 (#2226) :: renovate[bot]

## :heavy_check_mark: selenium-grid-0.30.0

- Chart is using image tag 4.20.0-20240425
- Chart is tested on Kubernetes versions: v1.26.15, v1.27.13, v1.28.9, v1.29.4, v1.30.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, 

### Fixed
- [`a83f0d6a`](http://github.com/seleniumhq/docker-selenium/commit/a83f0d6ab9d9337835ced36ceda4a44554d8a12c) - fix(chart): job to patch scaledobject stuck in deleting (#2222) :: Viet Nguyen Duc
- [`be0fe120`](http://github.com/seleniumhq/docker-selenium/commit/be0fe1207bb81a2fcf20bda6d2e50c7a14de4059) - fix(chart): remove hook post-upgrade, add test for chart upgrade capability :: Viet Nguyen Duc
- [`bd50206b`](http://github.com/seleniumhq/docker-selenium/commit/bd50206b1f92f237b054abaf312f0661a8ce2fa6) - fix(chart): node probe ignore proxy in sending request :: Viet Nguyen Duc

### Changed
- [`f39a9da8`](http://github.com/seleniumhq/docker-selenium/commit/f39a9da86f635b21d6dff0572e7713dc80c20d69) - [docs] pre-update for release docs generation :: Viet Nguyen Duc
- [`df742c98`](http://github.com/seleniumhq/docker-selenium/commit/df742c982f97a6552d11585c7fc7e9f4446073cb) - chore(deps): update helm release jaeger to v3 (#2213) :: renovate[bot]
- [`311b6382`](http://github.com/seleniumhq/docker-selenium/commit/311b63829cf652cad0f32fff2061cb45a7cd46d0) - chore(deps): update helm release kube-prometheus-stack to v58.1.2 (#2208) :: renovate[bot]
- [`ab3f8b85`](http://github.com/seleniumhq/docker-selenium/commit/ab3f8b8546f30da7ae88a308f63bc014718b6355) - chore(deps): update helm release kube-prometheus-stack to v58.1.1 (#2206) :: renovate[bot]
- [`70ed587d`](http://github.com/seleniumhq/docker-selenium/commit/70ed587dd3b99dd2633b23d313da7ac0a9ec12c9) - chore(deps): update helm release kube-prometheus-stack to v58.1.0 (#2205) :: renovate[bot]
- [`a3912b29`](http://github.com/seleniumhq/docker-selenium/commit/a3912b295e359601710bbf86018692194e3d9fbb) - chore(deps): update helm release kube-prometheus-stack to v58.0.1 (#2203) :: renovate[bot]
- [`12eb550a`](http://github.com/seleniumhq/docker-selenium/commit/12eb550a45559742fe161e949ffc34722261c3b9) - test: update CI test node-docker :: Viet Nguyen Duc
- [`033f77c0`](http://github.com/seleniumhq/docker-selenium/commit/033f77c02dde9d61d1a4d44be7526ef689244606) - chore(deps): update helm release jaeger to v2.1.0 (#2198) :: renovate[bot]
- [`2eab3722`](http://github.com/seleniumhq/docker-selenium/commit/2eab37227e01a9693ea604e08dcb3a4587525b5d) - chore(deps): update helm release kube-prometheus-stack to v58 (#2194) :: renovate[bot]
- [`25fdfee9`](http://github.com/seleniumhq/docker-selenium/commit/25fdfee9ddc79a19bee21d6e6da0492926c9b517) - chore(deps): update helm release kube-prometheus-stack to v57.2.1 (#2193) :: renovate[bot]
- [`74619b4c`](http://github.com/seleniumhq/docker-selenium/commit/74619b4c72700e52511f6e312b28a798cb04ac49) - chore(deps): update helm release kube-prometheus-stack to v57 (#2190) :: renovate[bot]
- [`ea556767`](http://github.com/seleniumhq/docker-selenium/commit/ea556767789a94124754172bd5c4dbc92ced17b0) - chore(deps): update helm release jaeger to v2 (#2189) :: renovate[bot]
- [`2ed16c21`](http://github.com/seleniumhq/docker-selenium/commit/2ed16c21425b44215960207d8a2b717a64e98e8a) - chore(deps): update helm release kube-prometheus-stack to v56.21.4 (#2187) :: renovate[bot]
- [`97781912`](http://github.com/seleniumhq/docker-selenium/commit/97781912a48b8262ae516fe62dfd05becdc70a71) - chore(deps): update helm release ingress-nginx to v4.10.0 (#2186) :: renovate[bot]
- [`06d8c18d`](http://github.com/seleniumhq/docker-selenium/commit/06d8c18de4c1bd703b41535190f27e767eee1bb4) - chore(deps): update helm release keda to v2.13.2 (#2184) :: renovate[bot]
- [`ce75e223`](http://github.com/seleniumhq/docker-selenium/commit/ce75e223c5cc306f0b7b0886a2ad2e4c0f74bc4b) - chore(deps): update helm release jaeger to v1.0.2 (#2183) :: renovate[bot]

## :heavy_check_mark: selenium-grid-0.29.1

- Chart is using image tag 4.19.1-20240402
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.12, v1.28.8, v1.29.3, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, 

### Fixed
- [`ca7155fa`](http://github.com/seleniumhq/docker-selenium/commit/ca7155faf587577d1e69d6d96c7cc5312b7a16ab) - fix(chart): node preStop - refresh node status in loop :: Viet Nguyen Duc
- [`6a6d1e1f`](http://github.com/seleniumhq/docker-selenium/commit/6a6d1e1f188a6992431925474ad16bb0ef688e52) - fix(chart: Use empty strings as defaults for some empty values (#2176) :: Maxim Manuylov

## :heavy_check_mark: selenium-grid-0.29.0

- Chart is using image tag 4.19.0-20240328
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.12, v1.28.8, v1.29.3, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, 

### Added
- [`fed2e1c6`](http://github.com/seleniumhq/docker-selenium/commit/fed2e1c6a0489584b6cc8af8bbd04b37815007d2) - feat(chart): enable automatic browser leftovers cleanup in chart :: Viet Nguyen Duc
- [`2eca4bbe`](http://github.com/seleniumhq/docker-selenium/commit/2eca4bbea12157928fdc3cd14decd2503456670b) - feat(chart): Configure fixed-sized thread pool for the Distributor in autoscaling :: Viet Nguyen Duc
- [`97941f86`](http://github.com/seleniumhq/docker-selenium/commit/97941f86643a0f3238f8fdb0c72b83d01fe430f0) - feat(chart): Configure fixed-sized thread pool for the Distributor to create new sessions :: Viet Nguyen Duc

### Fixed
- [`6f03eb1d`](http://github.com/seleniumhq/docker-selenium/commit/6f03eb1d06ac9d7e60f5912f5986e8a4eabc4049) - fix(chart): accessing .Values in templates (#2174) :: Maxim Manuylov
- [`db915980`](http://github.com/seleniumhq/docker-selenium/commit/db9159801c087b75031fb5ecacd368fdae54f3d4) - fix(chart): remove duplicate annotation (#2167) :: Mårten Svantesson

### Changed
- [`5a231077`](http://github.com/seleniumhq/docker-selenium/commit/5a2310778c03877043cdc585dc2265a976c21e9b) - docs: update rclone configs in sample :: Viet Nguyen Duc
- [`3c6015c0`](http://github.com/seleniumhq/docker-selenium/commit/3c6015c03f31121b2ece62ebbc925bbf88a4d67d) - Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.28.4

- Chart is using image tag 4.18.1-20240224
- Chart is tested on Kubernetes versions: v1.25.16 v1.26.14 v1.27.11 v1.28.7 v1.29.2 
- Chart is tested on Helm versions: v3.10.3 v3.11.3 v3.12.3 v3.13.3 v3.14.2 

### Fixed
- fix(chart): connection in script of Node startup probe and preStop lifecycle :: Viet Nguyen Duc
- fix(chart): `autoscaling.terminationGracePeriodSeconds` is not set in Node spec :: Viet Nguyen Duc

### Changed
- Release chart 0.28.4 :: Viet Nguyen Duc
- update(chart): add annotations checksum for ConfigMap and Secret :: Viet Nguyen Duc
- test(chart): update chart values for CI tests :: Viet Nguyen Duc
- test(chart): autoscaling as job :: Viet Nguyen Duc
- Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.28.3

- Chart is using image tag 4.18.1-20240224
- Chart is tested on Kubernetes versions: v1.25.16 v1.26.14 v1.27.11 v1.28.7 v1.29.2 

### Fixed
- fix(chart): fix object naming and add test to verify :: Viet Nguyen Duc

### Changed
- Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.28.2

- Chart is using image tag 4.18.1-20240224
- Chart is tested on Kubernetes versions: v1.25.16 v1.26.14 v1.27.11 v1.28.7 v1.29.2 

### Added
- feat(chart): option to disable release name prefix in object naming :: Viet Nguyen Duc

### Fixed
- fix(chart): extra scripts can be imported in sub-chart by default :: Viet Nguyen Duc

### Changed
- release(chart): 0.28.2 :: Viet Nguyen Duc
- Update tag in docs and files :: Selenium CI Bot
- test(chart): test extra scripts import when import as sub-chart :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.28.1

- Chart is using image tag 4.18.0-20240220
- Chart is tested on Kubernetes versions: v1.25.16 v1.26.14 v1.27.11 v1.28.7 v1.29.2

### Fixed
- bug(chart): template issue when chart is imported as dependency in umbrella charts :: Viet Nguyen Duc
- bug(chart): SE_NODE_GRID_URL missing port when `hostname` is `selenium-grid.local` :: Viet Nguyen Duc
- bug(chart) CRITICAL: Node startup probe loop infinite when ingress hostname is set :: Viet Nguyen Duc

### Changed
- test(chart): update docs :: Viet Nguyen Duc
- test(chart): add tests for the case basic auth is enabled :: Viet Nguyen Duc
- test(chart): add tests for the case ingress is enabled with `hostname` set :: Viet Nguyen Duc
- build(chart): change log and release notes for helm chart :: Viet Nguyen Duc

## :heavy_check_mark: selenium-grid-0.28.0

- Chart is using image tag 4.18.0-20240220
- Chart is tested on Kubernetes versions: v1.25.16 v1.26.14 v1.27.11 v1.28.7 v1.29.2

### Added
- feat: enable tracing observability in docker-compose and helm chart (#2137) :: Viet Nguyen Duc
- feat: video upload supports both docker-compose and helm chart (#2131) :: Viet Nguyen Duc
- feat(chart): set components host & port point to its service :: Viet Nguyen Duc
- feat: non-root user for video recorder (#2122) :: Viet Nguyen Duc
- feat(chart): Log Node preStop exec to console :: Viet Nguyen Duc
- feat(chart): delete file after upload (#2117) :: Doofus100500

### Changed
- Update tag in docs and files :: Selenium CI Bot
- Release 4.18.0 :: Viet Nguyen Duc
- test(chart): CI tests run against different Kubernetes version :: Viet Nguyen Duc
- update(tracing): Use OTLP exporter instead of Jaeger specific :: Viet Nguyen Duc
- update(chart): Node preStop and startupProbe in autoscaling Deployment (#2139) :: Viet Nguyen Duc
- update(chart): objects name convention with prefix is chart RELEASENAME (#2134) :: Viet Nguyen Duc
- [🚀 Feature]: Update objects name convention with prefix is Chart RELEASENAME #2109 (#2120) :: Bas M
- update(chart): Make var RECORD_VIDEO lowercase before comparison (#2128) :: Doofus100500
- test(chart): parallel with autoscalingType deployment & job :: Viet Nguyen Duc
- docs(chart): point shielding in README (#2116) :: Doofus100500
- Update chart CHANGELOG [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.27.0

- Chart is using image tag 4.17.0-20240123

### Added
- feat(chart): templating in name(Override) for new object [deploy] :: Viet Nguyen Duc
- feat(chart): templating in name(Override) (#2107) :: Bas M
- feat(chart): Add node registration secret to exec preStop container Update default scalingStrategy.strategy: accurate [skip ci] :: Viet Nguyen Duc
- feat(chart): Configuration extra scripts mount to container (#2105) :: Viet Nguyen Duc
- feat(chart): Bump dependency charts KEDA and Ingress-NGINX version (#2103) :: Viet Nguyen Duc
- feat(chart): Add RCLONE as default video uploader on Kubernetes (#2100) :: Viet Nguyen Duc
- feat(chart): videoRecorder getting scripts from external files (#2095) :: Viet Nguyen Duc
- feat(chart): Add config to control disabling Grid UI (#2083) :: Viet Nguyen Duc
- feat(chart): Simplify to enable HTTPS/TLS in Selenium Grid on Kubernetes (#2080) :: Viet Nguyen Duc
- feat(chart): Simplify config ports, probes, lifecycle hooks for Nodes (#2077) :: Viet Nguyen Duc

### Changed
- Update tag in docs and files :: Selenium CI Bot
-  feat(chart): se:recordVideo should be used to determine if record video (#2104) :: Viet Nguyen Duc
- [build] Fix duplicated Nightly releases creation :: Viet Nguyen Duc
- build(chart): Chart built on top of Nightly images (#2089) :: Viet Nguyen Duc
- Update chart CHANGELOG [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.26.4

- Chart is using image tag 4.16.1-20231219

### Fixed
- fix(chart): Remove trailing slash from default subPath value (#2076) :: Viet Nguyen Duc

### Changed
- Update chart CHANGELOG [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.26.3

- Chart is using image tag 4.16.1-20231219

### Added
- feat(chart): Simplify to access Selenium Grid from outside of Kubernetes (#2073) :: Viet Nguyen Duc
- feat(chart): Simplify to change log level in Kubernetes (#2072) :: Viet Nguyen Duc

### Fixed
- bug: ENV variable SE_VNC_PASSWORD contains sensitive data (#2061) :: Viet Nguyen Duc

### Changed
- Update tag in docs and files :: Selenium CI Bot
- Update chart CHANGELOG [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.26.2

- Chart is using image tag 4.16.1-20231212

### Changed
- Update tag in docs and files :: Selenium CI Bot
- Update chart CHANGELOG [skip ci] :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.26.1

- Chart is using image tag 4.16.1-20231208

### Added
- Add script to generate chart CHANGELOG after released (#2054) :: Viet Nguyen Duc
- feat(chart): Append subPath to ENV variable SE_NODE_GRID_URL (#2053) :: Viet Nguyen Duc

### Changed
- Update tag in docs and files :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.26.0

- Chart is using image tag 4.16.0-20231206

### Added
- feat(chart): Add default annotations for ingress nginx controller (#2047) :: Viet Nguyen Duc
- feat: Video image with based FFmpeg-6.1 on Ubuntu-22.04 (#2042) :: Viet Nguyen Duc

### Fixed
- bug(#1824): Container ENV SE_NODE_SESSION_TIMEOUT not take effect (#2044) :: Viet Nguyen Duc
- bug(#2038): Rollback io.opentelemetry 1.31.0 - add test tracing enabled (#2040) :: Viet Nguyen Duc

### Changed
- Update tag in docs and files :: Selenium CI Bot
- Update chart CHANGELOG [skip ci] :: Viet Nguyen Duc
- test(chart): Parallel tests execution against autoscaling in Kubernetes (#2046) :: Viet Nguyen Duc
- test(chart): Chart template render and assert output (#2043) :: Viet Nguyen Duc
- test(chart): Add test for setting registry to pull images (#2036) :: Viet Nguyen Duc

## :heavy_check_mark: 0.25.3

### Changed
- Update image tag to 4.16.0-20231206
- Update tag in docs and files :: Selenium CI Bot
- test: Add sanity test for download file (#2034) [deploy] :: Viet Nguyen Duc
- feat(chart): distribution registry can be set global and individual component (#2030) :: Viet Nguyen Duc
- Update tag in docs and files [skip ci] :: Selenium CI Bot
- test: Sanity tests Selenium Grid chart via Makefile commands (#2029) :: Viet Nguyen Duc
- Feature run selenium tests grid on kubernetes via helm chart (#2027) :: Amar Deep Singh
- feat: CI Bot bump chart version along with new deploy image version (#2028) :: Viet Nguyen Duc
- Update NodeChrome support latest version from GoogleChromeLabs (#2018) :: Viet Nguyen Duc
- Update tag in docs and files [skip ci] :: Selenium CI Bot
- corrected typo in selenium grid charts (#2010) :: Thabelo Ramabulana

## :heavy_check_mark: 0.25.1

### Changed
- Update image tag to 4.15.0-20231110
- Bug: Error setting name in helm release #2006 #2007 (#2009) :: Viet Nguyen Duc

## :heavy_check_mark: 0.25.0

### Changed
- Update image tag to 4.15.0-20231110
- feat(helm-test): Added helm test and linting (#2003) :: Amar Deep Singh
- Update tag in docs and files [skip ci] :: Selenium CI Bot
- Update tag in docs and files [skip ci] :: Selenium CI Bot
- feat: Adding port to nodes service (#1996) :: Viet Nguyen Duc

## :heavy_check_mark: 0.24.0

### Changed
- Update image tag to 4.15.0-20231102
- Bumping chart version :: Viet Nguyen Duc
- Add chart parameter ingress.paths to configure custom paths (#1994) :: Viet Nguyen Duc
- feat(autoscaling): Unified parameters to set scaled options for browser nodes (#1989) :: Viet Nguyen Duc
- Update tag in docs and files [skip ci] :: Selenium CI Bot
- Improve chart templates in the section videoRecorder (#1987) :: Viet Nguyen Duc
- Improve default value for videoRecorder in chart (#1984) :: Viet Nguyen Duc
- Fix minor issues after PR #1881 and #1981 (#1983) :: Viet Nguyen Duc

## :heavy_check_mark: 0.23.0

### Added

- Update tag in docs and files [skip ci] :: Selenium CI Bot
- feat: video recording with pluggable upload container (#1881) :: Mårten Svantesson
- Update Video/Dockerfile with based image ffmpeg:6.0-alpine (#1981) :: Viet Nguyen Duc

### Changed
- Update image tag to 4.14.1-20231025

## :heavy_check_mark: 0.22.0

### Added
-  feat(keda): bumped up keda 2.12.0 (#1960) :: Amar Deep Singh
-  Add missing Ingress namespace field (#1966) :: Cody Lent

### Changed
- Update image tag to 4.13.0-20231004

## :heavy_check_mark: 0.21.3

### Changed
- Update image tag to  4.13.0-20230926

## :heavy_check_mark: 0.21.2

### Changed
- Update image tag to 4.12.1-20230920

## :heavy_check_mark: 0.21.1

### Changed
- Update image tag to 4.12.1-20230912

## :heavy_check_mark: 0.21.0

### Added
- feat: Add option to inject sidecars into Node Pods (#1938) 
- Add minReplicaCount, remove replicas if autoscaling is enabled (#1932) 

## :heavy_check_mark: 0.20.1

### Changed
- Update image tag to 4.12.1-20230904

## :heavy_check_mark: 0.20.0

### Added
- fix missing securityContext in nodes (#1907) :: balazs92117
- Support to nodes livenessProbe into the Helm Chart (#1897) :: Bruno Brito
- helm chart VolumeMounts & Volumes for Selenium hub (#1893) :: Yoga Yu

### Changed
- Update image tag to 4.11.0-20230801

## :heavy_check_mark: 0.19.0

### Added
-  Autoscaling selenium grid on kubernetes with scaledjobs (#1854) 

## :heavy_check_mark: 0.18.1

### Changed
- Update image tag to 4.10.0-20230607

## :heavy_check_mark: 0.18.0

### Added
- Add affinity to helm charts (#1851) 

## :heavy_check_mark: 0.17.0

### Added
- Make deployment securityContext configurable via values.yaml (#1845) 

## :heavy_check_mark: 0.16.1

### Changed
- Update image tag to  4.9.1-20230508

## :heavy_check_mark: 0.16.0

### Added
- Custom Ingress Path for Helm Chart (#1834) 

## :heavy_check_mark: 0.15.8

### Changed
- Update image tag to 4.9.0-20230421

## :heavy_check_mark: 0.15.7

### Changed
- Update image tag to 4.8.3-20230328

## :heavy_check_mark: 0.15.6

### Changed
- Update image tag to 4.8.3-20230328

## :heavy_check_mark: 0.15.5

### Changed
- Update image tag to 4.8.2-20230325

## :heavy_check_mark: 0.15.4

### Changed
- Update image tag to 4.8.1-20230306

## :heavy_check_mark: 0.15.3

### Changed
- Make ingress compatible with format prior to 1.19-0 k8s version

## :heavy_check_mark: 0.15.2

### Changed
- Update image tag to 4.8.1-20230221

## :heavy_check_mark: 0.15.1

### Changed
- Update image tag to 4.8.0-20230210

## :heavy_check_mark: 0.15.0

### Changed
- Update image tag to 4.8.0-20230123

## :heavy_check_mark: 0.14.3

### Changed
- Update image tag to 4.7.2-20221219

## :heavy_check_mark: 0.14.2

### Changed
- Update image tag to 4.7.2-20221217

## :heavy_check_mark: 0.14.1

### Changed
- Update image tag to 4.7.1-20221208

## :heavy_check_mark: 0.14.0

### Changed
- Update image tag to 4.7.0-20221202

## :heavy_check_mark: 0.13.1

### Changed
- Update image tag to  4.6.0-20221104

## :heavy_check_mark: 0.13.0

### Added
- Added support to disable Chrome, Edge, and Firefox Deployment using `deploymentEnabled`

## :heavy_check_mark: 0.12.2

### Changed
- Update image tag to  4.6.0-20221024

## :heavy_check_mark: 0.12.1

### Changed
- Update image tag to  4.5.0-20221017

## :heavy_check_mark: 0.12.0

### Changed
- Remove EventBus from SessionQueue environment variables

## :heavy_check_mark: 0.11.0

### Added
- Adds helm-chart releaseName to all selectors in resources

### Changed
- Update image tag to 4.5.0-20221004

## :heavy_check_mark: 0.10.0

### Changed
- Bump version chart

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
