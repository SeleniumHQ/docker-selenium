## :heavy_check_mark: selenium-grid-0.44.2

- Chart is using image tag 4.33.0-20250606
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.13,v1.31.9,v1.32.5,v1.33.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.3,v3.18.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.1

### Changed
- [`5efe4cf2`](http://github.com/seleniumhq/docker-selenium/commit/5efe4cf26bd518d7cd7c30eb46c5932329c3f66a) - [ci] Update tag 4.33.0-20250606 in docs and files :: Selenium CI Bot
- [`c06d1a24`](http://github.com/seleniumhq/docker-selenium/commit/c06d1a24f33e9f96d506f4c8c438e6d93bd2095b) - K8s: Helm config `customLabels` to add more tracing resource attributes (#2858) :: Viet Nguyen Duc
- [`1989f7b8`](http://github.com/seleniumhq/docker-selenium/commit/1989f7b899b0f265bbb5bd8fd7c38b831f86a7e0) - Update Helm release kube-prometheus-stack to v73 (#2853) :: renovate[bot]
- [`fb86e414`](http://github.com/seleniumhq/docker-selenium/commit/fb86e41490cca3e6c8e083191f745e82cd6b9aad) - K8s: Add chart config `autoscaling.setReplicasInSpec` in case ArgoCD with AutoSync :: Viet Nguyen Duc
- [`10fa7b3d`](http://github.com/seleniumhq/docker-selenium/commit/10fa7b3d21df27e442038e78b23b57ce0ce881e4) - [ci] Update chart 0.44.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.44.0

- Chart is using image tag 4.33.0-20250525
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.13,v1.31.9,v1.32.5,v1.33.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.3,v3.18.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.1

### Changed
- [`798600fc`](http://github.com/seleniumhq/docker-selenium/commit/798600fce2b0d655e596f738b09a3d2ae50dbe88) - [ci] Update tag 4.33.0-20250525 in docs and files :: Selenium CI Bot
- [`365c1065`](http://github.com/seleniumhq/docker-selenium/commit/365c10659905e6ad5e7e972fcb54225dc2a8c928) - K8s: Fix template issue on Helm version v3.18.0 :: Viet Nguyen Duc
- [`cc36ea9b`](http://github.com/seleniumhq/docker-selenium/commit/cc36ea9b67278d8673f132970ae3f108e3e0b1c7) - K8s: Video recorder run as sidecar container is disabled by default (#2843) :: Viet Nguyen Duc
- [`fb966b8f`](http://github.com/seleniumhq/docker-selenium/commit/fb966b8f00c1bcbaf3004c4c6436df6e3679bb00) - [ci] Update chart 0.43.2 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.43.2

- Chart is using image tag 4.32.0-20250515
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.13,v1.31.9,v1.32.5,v1.33.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.3
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.1

### Changed
- [`58279951`](http://github.com/seleniumhq/docker-selenium/commit/58279951254045eb307f30229f0c0545f85b8404) - [ci] Update tag 4.32.0-20250515 in docs and files :: Selenium CI Bot
- [`88991ee3`](http://github.com/seleniumhq/docker-selenium/commit/88991ee3795a40e7e44eb30579dc2d63724786c2) - Update Helm release kube-prometheus-stack to v72 (#2816) :: renovate[bot]
- [`e2abe9fb`](http://github.com/seleniumhq/docker-selenium/commit/e2abe9fb06b20c3a373d98338e26a093ad1447f9) - K8s: Node enable readiness probe checks status registered to Hub (#2833) :: Viet Nguyen Duc
- [`7957b999`](http://github.com/seleniumhq/docker-selenium/commit/7957b9992517ee5d42c6ce5ccad76cde4d8105d5) - [ci] Update chart 0.43.1 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.43.1

- Chart is using image tag 4.32.0-20250505
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.0

### Changed
- [`752bd109`](http://github.com/seleniumhq/docker-selenium/commit/752bd109e55e49fc1020d6d130970371cfc8a837) - Helm: Release chart 0.43.1 :: Viet Nguyen Duc
- [`74149de8`](http://github.com/seleniumhq/docker-selenium/commit/74149de8ec0956cb61afbd1f1d067e0eee8a39f9) - K8s: Fix deployment config error in video-manager (#2831) :: Viet Nguyen Duc
- [`7d4d65fa`](http://github.com/seleniumhq/docker-selenium/commit/7d4d65fa189264bb9607d078c27492b10cdc4951) - K8s: Fix deployment template error in video-manager (#2828) :: Viet Nguyen Duc
- [`f7bc3fb7`](http://github.com/seleniumhq/docker-selenium/commit/f7bc3fb7facd980ff4ac54945c578bcc2ff14588) - Update Helm release redis to v21 (#2826) :: renovate[bot]
- [`17aeb6d3`](http://github.com/seleniumhq/docker-selenium/commit/17aeb6d3b820674031d7204166cdca0d6b7272a5) - [ci] Update chart 0.43.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.43.0

- Chart is using image tag 4.32.0-20250505
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.0

### Changed
- [`f8a7a68b`](http://github.com/seleniumhq/docker-selenium/commit/f8a7a68b549299dcf726c42eb7a6e9971a30bb13) - [ci] Update tag 4.32.0-20250505 in docs and files :: Selenium CI Bot
- [`78ff7f68`](http://github.com/seleniumhq/docker-selenium/commit/78ff7f681ceb9f3092f62d57529f04475e776a83) - Update Helm release kube-prometheus-stack to v71 (#2815) :: renovate[bot]
- [`25b72891`](http://github.com/seleniumhq/docker-selenium/commit/25b728915ae4b0276bb070cbc1e22b8d2510a2bf) - Update Helm release kube-prometheus-stack to v70.10.0 (#2809) :: renovate[bot]
- [`88642195`](http://github.com/seleniumhq/docker-selenium/commit/88642195025a565794d1d5ee108d61e75ebfcd19) - Update Helm release redis to v20.13.4 (#2814) :: renovate[bot]
- [`e3b1899f`](http://github.com/seleniumhq/docker-selenium/commit/e3b1899f9495bf3a7d8b62c3657c87f49f8a2765) - Update Helm release redis to v20.13.3 (#2810) :: renovate[bot]
- [`3aab80d6`](http://github.com/seleniumhq/docker-selenium/commit/3aab80d60453c7c45c7854e046e22dfba48ee596) - Update Helm release ingress-nginx to v4.12.2 (#2811) :: renovate[bot]
- [`1746b4ac`](http://github.com/seleniumhq/docker-selenium/commit/1746b4ac8bff0850d8f24888a5095e2552b97cd6) - Update Helm release postgresql to v16.6.6 (#2806) :: renovate[bot]
- [`880a513c`](http://github.com/seleniumhq/docker-selenium/commit/880a513c2c3e8d5bc0e107f5c03511d919c142c9) - Update Helm release redis to v20.13.2 (#2803) :: renovate[bot]
- [`3f902e7c`](http://github.com/seleniumhq/docker-selenium/commit/3f902e7c6604294a61f8522997d00c9707dbd2b3) - Update Helm release kube-prometheus-stack to v70.8.0 (#2805) :: renovate[bot]
- [`70d7f929`](http://github.com/seleniumhq/docker-selenium/commit/70d7f92953e6f0851381d4c57c48659349b56a39) - Update Helm release postgresql to v16.6.5 (#2802) :: renovate[bot]
- [`96155a44`](http://github.com/seleniumhq/docker-selenium/commit/96155a44cf4e96bbae90096c1b6f68ec795726e0) - Update Helm release redis to v20.13.1 (#2801) :: renovate[bot]
- [`c2c9f0e2`](http://github.com/seleniumhq/docker-selenium/commit/c2c9f0e28209d2f23909224b2f557200151fd77a) - Update Helm release postgresql to v16.6.4 (#2800) :: renovate[bot]
- [`5d49cc63`](http://github.com/seleniumhq/docker-selenium/commit/5d49cc63f3d4fe2cc4ee147e07b819c8dee5d0de) - Update Helm release redis to v20.12.2 (#2797) :: renovate[bot]
- [`be0c3462`](http://github.com/seleniumhq/docker-selenium/commit/be0c3462005ec6e57b451605b5fc92f8e57ac8af) - [docs] Update note in chart values :: Viet Nguyen Duc
- [`44f46584`](http://github.com/seleniumhq/docker-selenium/commit/44f46584226c217d8cff06369053194d4c55c4af) - Update Helm release kube-prometheus-stack to v70.7.0 (#2794) :: renovate[bot]
- [`3f7b0b09`](http://github.com/seleniumhq/docker-selenium/commit/3f7b0b09ef73ec353d69249244204083b306ad68) - Update Helm release redis to v20.12.1 (#2793) :: renovate[bot]
- [`0cdd6ec9`](http://github.com/seleniumhq/docker-selenium/commit/0cdd6ec93e9f09493763d556d1877b96f3740f79) - Update Helm release kube-prometheus-stack to v70.5.0 (#2790) :: renovate[bot]
- [`ddd2ec07`](http://github.com/seleniumhq/docker-selenium/commit/ddd2ec07789ebbde7fa37320211b30c73ac9605c) - Update Helm release redis to v20.12.0 (#2789) :: renovate[bot]
- [`f9c72df7`](http://github.com/seleniumhq/docker-selenium/commit/f9c72df7b71f2efe48a1906de22f4c34c4dabe81) - [ci] Update chart 0.42.1 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.42.1

- Chart is using image tag 4.31.0-20250414
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.0

### Changed
- [`614242b8`](http://github.com/seleniumhq/docker-selenium/commit/614242b856031c44c06dbc8ca73ca33b4bdd44b1) - [ci] Update tag 4.31.0-20250414 in docs and files :: Selenium CI Bot
- [`cb786352`](http://github.com/seleniumhq/docker-selenium/commit/cb7863526c7c86c25f34642baffe46c6069e60de) - Docker: Update basic auth headers in util scripts (#2779) :: Viet Nguyen Duc
- [`35b2d0e1`](http://github.com/seleniumhq/docker-selenium/commit/35b2d0e14e714568c607165cfc73fd4d849cdf4f) - [ci] Update chart configuration table :: Selenium CI Bot
- [`9bd4d8a7`](http://github.com/seleniumhq/docker-selenium/commit/9bd4d8a7deab9aab337986bffa180da5a44da5c0) - K8s: Add ability to config trigger name (#2777) :: Romain THERRAT
- [`b6c1227d`](http://github.com/seleniumhq/docker-selenium/commit/b6c1227d696442215a97303227d7f12f9c3a449c) - Update Helm release redis to v20.11.5 (#2772) :: renovate[bot]
- [`a07c626d`](http://github.com/seleniumhq/docker-selenium/commit/a07c626d50b1c96c0b5879b2a660c1c5942f4559) - Update Helm release postgresql to v16.6.3 (#2773) :: renovate[bot]
- [`8f280e1b`](http://github.com/seleniumhq/docker-selenium/commit/8f280e1be538fa4d2411306c52db25be59ea786b) - [ci] Update chart 0.42.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.42.0

- Chart is using image tag 4.31.0-20250404
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.17.0

### Fixed
- [`e1631d56`](http://github.com/seleniumhq/docker-selenium/commit/e1631d5681e3298901c27beb3919874288a96e95) - Fix lint chart values :: Viet Nguyen Duc

### Changed
- [`1bf02dad`](http://github.com/seleniumhq/docker-selenium/commit/1bf02dadeef1e6c53e7bedde670eb7016388b1e2) - [ci] Update tag 4.31.0-20250404 in docs and files :: Selenium CI Bot
- [`9efdd3e0`](http://github.com/seleniumhq/docker-selenium/commit/9efdd3e0e29f9e1257d28cebb605089c5efee340) - K8s: Add template for file browser video records service (#2763) :: Viet Nguyen Duc
- [`9348ed1b`](http://github.com/seleniumhq/docker-selenium/commit/9348ed1bc845bd773473ad0ec8ff9229129f64b3) - K8s: Strictly handle `basicAuth.enabled` in template (#2760) :: Viet Nguyen Duc
- [`c2ac0473`](http://github.com/seleniumhq/docker-selenium/commit/c2ac047331551e298482997fb21d3de2a5db8348) - Update Helm release postgresql to v16.6.2 (#2759) :: renovate[bot]
- [`402592bd`](http://github.com/seleniumhq/docker-selenium/commit/402592bd62f823ffc093a38acd3cc22dd0c64d91) - Update Helm release keda to v2.17.0 (#2758) :: renovate[bot]
- [`1fe8d6e4`](http://github.com/seleniumhq/docker-selenium/commit/1fe8d6e492c754e07d5ec3bef92bdf67343c2b5e) - Update Helm release kube-prometheus-stack to v70.4.2 (#2757) :: renovate[bot]
- [`83093214`](http://github.com/seleniumhq/docker-selenium/commit/8309321489a873f91972ce748c3c378721efd257) - Update Helm release postgresql to v16.6.1 (#2756) :: renovate[bot]
- [`d34cc0d4`](http://github.com/seleniumhq/docker-selenium/commit/d34cc0d4e72f2f69be1009d361a4a6ec70d95f55) - K8s: Update strategy as Recreate by default (#2755) :: Viet Nguyen Duc
- [`26c45cdb`](http://github.com/seleniumhq/docker-selenium/commit/26c45cdb94ba40fb2ba0423098eb68d626743f82) - K8s: Config  is true by default :: Viet Nguyen Duc
- [`1cca6ba8`](http://github.com/seleniumhq/docker-selenium/commit/1cca6ba8ef0d5ad1026a3c894a57164dfc275b38) - Update Helm release kube-prometheus-stack to v70.4.1 (#2747) :: renovate[bot]
- [`77a23f7a`](http://github.com/seleniumhq/docker-selenium/commit/77a23f7a73f439013f419104520f5ccc3cdabd16) - Update Helm release kube-prometheus-stack to v70.4.0 (#2744) :: renovate[bot]
- [`4c35f64b`](http://github.com/seleniumhq/docker-selenium/commit/4c35f64befa0b0627e3abb3fb87e708eb874afbe) - [ci] Update chart 0.41.1 changelog :: Selenium CI Bot
- [`f310b3d4`](http://github.com/seleniumhq/docker-selenium/commit/f310b3d4faae94e6321f2c02b6715dde0ca3d6cf) - Update Helm release postgresql to v16.6.0 (#2741) :: renovate[bot]

## :heavy_check_mark: selenium-grid-0.41.1

- Chart is using image tag 4.30.0-20250323
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250323
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Fixed
- [`523f738c`](http://github.com/seleniumhq/docker-selenium/commit/523f738cf721f5b1e5d3631126138b0c97b251c4) - Fix: Restore a Mistakenly Deleted `%s` Format Specifier in Template (#2740) :: KenHuPricer

### Changed
- [`9066e332`](http://github.com/seleniumhq/docker-selenium/commit/9066e332c74eb9b6bbab18a9e97dc2b057164795) - K8s: Update chart version 0.41.1 :: Viet Nguyen Duc
- [`76fc54f9`](http://github.com/seleniumhq/docker-selenium/commit/76fc54f95d0d85709537bdecbd1876c76933d573) - Update Helm release kube-prometheus-stack to v70.3.0 (#2735) :: renovate[bot]
- [`b9bacd8b`](http://github.com/seleniumhq/docker-selenium/commit/b9bacd8bc05b581edbce41180dc85e5bc7ce4c51) - Update Helm release postgresql to v16.5.6 (#2731) :: renovate[bot]
- [`6dbfbbfa`](http://github.com/seleniumhq/docker-selenium/commit/6dbfbbfa9ca5c32e63a550dbf8f2ef4c127e16d6) - Update Helm release ingress-nginx to v4.12.1 (#2736) :: renovate[bot]
- [`5fe6e7c4`](http://github.com/seleniumhq/docker-selenium/commit/5fe6e7c465e582d25e00bd9834ff7d5106d52a0c) - [ci] Update tag 4.30.0-20250323 in docs and files :: Selenium CI Bot
- [`b283ba1b`](http://github.com/seleniumhq/docker-selenium/commit/b283ba1b5d64eee42849743d0f9196270c530aae) - [ci] Update chart 0.41.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.41.0

- Chart is using image tag 4.30.0-20250323
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.15,v1.30.11,v1.31.7,v1.32.3
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250323
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Changed
- [`41e3b6da`](http://github.com/seleniumhq/docker-selenium/commit/41e3b6dad17f03f7ba3a351a343bf0d54eaf7834) - [ci] Update tag 4.30.0-20250323 in docs and files :: Selenium CI Bot
- [`09a1cb75`](http://github.com/seleniumhq/docker-selenium/commit/09a1cb75153f9cb91801d0265b528d6984561789) - Update Helm release kube-prometheus-stack to v70.2.1 (#2729) :: renovate[bot]
- [`51ea5ac6`](http://github.com/seleniumhq/docker-selenium/commit/51ea5ac61ec9b66ea79fff03fe6ded50608a4f28) - Update Helm release postgresql to v16.5.5 (#2718) :: renovate[bot]
- [`e9dd2e83`](http://github.com/seleniumhq/docker-selenium/commit/e9dd2e83691d0ab86f64136019c49cc462f55f26) - Update Helm release jaeger to v3.4.1 (#2723) :: renovate[bot]
- [`d62207f6`](http://github.com/seleniumhq/docker-selenium/commit/d62207f6f2e72d4be4ea8eac630ff827ffe6ac15) - Update Helm release kube-prometheus-stack to v70.1.1 (#2717) :: renovate[bot]
- [`2e818562`](http://github.com/seleniumhq/docker-selenium/commit/2e818562471de06236accffd8f9e31ccd6ca781e) - Update Helm release redis to v20.11.4 (#2727) :: renovate[bot]
- [`da16f65b`](http://github.com/seleniumhq/docker-selenium/commit/da16f65b5bc19fd6b87c311759ab02f2727170dd) - K8s: Disable annotation when `ingress.tls[0].secretName` is null (#2724) :: Viet Nguyen Duc
- [`b6df8d58`](http://github.com/seleniumhq/docker-selenium/commit/b6df8d58ff36300d318a95ac772b32b4471b1453) - Update Helm release kube-prometheus-stack to v70.1.0 (#2715) :: renovate[bot]
- [`94ee101e`](http://github.com/seleniumhq/docker-selenium/commit/94ee101e19b34c4a4c250036599f4289c7375a52) - [ci] Update chart configuration table :: Selenium CI Bot
- [`7e63e01c`](http://github.com/seleniumhq/docker-selenium/commit/7e63e01c55bb4edc5c7e985ab92f9b5607b683c0) - Update Helm release jaeger to v3.4.0 (#2711) :: renovate[bot]
- [`48f6e78a`](http://github.com/seleniumhq/docker-selenium/commit/48f6e78a0980c5d184784f16bd17fd012192c1b6) - Update Helm release postgresql to v16.5.2 (#2712) :: renovate[bot]
- [`c34ecb88`](http://github.com/seleniumhq/docker-selenium/commit/c34ecb88887f5ff155500e244309f9ef7c751b0e) - Update Helm release redis to v20.11.3 (#2713) :: renovate[bot]
- [`d5749065`](http://github.com/seleniumhq/docker-selenium/commit/d5749065ffc4e623fc2dc742ef0fd37d951053b0) - K8s: Node Relay to extend autoscaling Grid with test cloud resources (#2703) :: Viet Nguyen Duc
- [`dd1ff4be`](http://github.com/seleniumhq/docker-selenium/commit/dd1ff4be2abd55639860051989de6019ab0ca5c3) - K8s: Improve job to clean up scaledobjects are leftover (#2710) :: Viet Nguyen Duc
- [`c95fc277`](http://github.com/seleniumhq/docker-selenium/commit/c95fc2771cb02e354d2d015f4dc074f1194de257) - Update Helm release kube-prometheus-stack to v70 (#2707) :: renovate[bot]
- [`dad1ecd5`](http://github.com/seleniumhq/docker-selenium/commit/dad1ecd50c34c5528dde792394cdb1f3365d6736) - [ci] Update chart 0.40.1 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.40.1

- Chart is using image tag 4.29.0-20250303
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.14,v1.30.10,v1.31.6,v1.32.2
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1,27.5.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250303
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Changed
- [`cbf87030`](http://github.com/seleniumhq/docker-selenium/commit/cbf8703009990f5757e7ebe65ae6bde2b2d55c59) - [ci] Update tag 4.29.0-20250303 in docs and files :: Selenium CI Bot
- [`70ac588d`](http://github.com/seleniumhq/docker-selenium/commit/70ac588d567b253c93c91d990a5b197f5f8d146a) - Update Helm release kube-prometheus-stack to v69.7.2 (#2679) :: renovate[bot]
- [`966a78a3`](http://github.com/seleniumhq/docker-selenium/commit/966a78a3b3a3c770bff5041ae25d5d5a79381141) - Docker: Resolve default component port via env var (#2689) :: Viet Nguyen Duc
- [`7276e544`](http://github.com/seleniumhq/docker-selenium/commit/7276e544b0f4d5254ef728875a43586f8467d146) - K8s: Update Helm configs for setting Node custom capabilities (#2686) :: Viet Nguyen Duc
- [`1b424655`](http://github.com/seleniumhq/docker-selenium/commit/1b424655a6c472de7b855d29c76256c2fd706f11) - K8s: Bump new KEDA image for feature preview (#2681) :: Viet Nguyen Duc
- [`6f262a31`](http://github.com/seleniumhq/docker-selenium/commit/6f262a317e57ec48cf1348629249f3b9ca2c373a) - [docs] Update project contact email :: Viet Nguyen Duc
- [`5bc5b205`](http://github.com/seleniumhq/docker-selenium/commit/5bc5b20585f2d35950f76ac8e6a7c21a279d66b2) - [ci] Update chart 0.40.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.40.0

- Chart is using image tag 4.29.0-20250222
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.13,v1.30.9,v1.31.5,v1.32.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250222
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Fixed
- [`5648285b`](http://github.com/seleniumhq/docker-selenium/commit/5648285bda6d88a74c32dcc8865572a2cb79023e) - Fix add-cert-helper.sh only adding a single certificate in Chrome (#2660) :: Peter Upfold

### Changed
- [`dc3f59d5`](http://github.com/seleniumhq/docker-selenium/commit/dc3f59d5bae6e2bd1a022c7897dd379a2ceebc06) - [ci] Update tag 4.29.0-20250222 in docs and files :: Selenium CI Bot
- [`6f41a42b`](http://github.com/seleniumhq/docker-selenium/commit/6f41a42b9429cc8953371f98cea093e31fadcd25) - [ci] Update browser versions matrix :: Viet Nguyen Duc
- [`ccbcbd8f`](http://github.com/seleniumhq/docker-selenium/commit/ccbcbd8f57ad3bc53d472dc335c0bfe7634f94ba) - Update Helm release kube-prometheus-stack to v69.4.1 (#2670) :: renovate[bot]
- [`031fb6c2`](http://github.com/seleniumhq/docker-selenium/commit/031fb6c24bc341135e3bcd9dd381b4f0ebbd4cdc) - Update Helm release kube-prometheus-stack to v69.4.0 (#2669) :: renovate[bot]
- [`83f6c087`](http://github.com/seleniumhq/docker-selenium/commit/83f6c087341cb65ddf6136ab1b982f366013fc9c) - K8s: Set K8s node IP to all components via env var KUBERNETES_NODE_HOST_IP (#2668) :: Viet Nguyen Duc
- [`be6f2613`](http://github.com/seleniumhq/docker-selenium/commit/be6f2613d45a7470cd7e31dd46d5bfc987be1283) - Update Helm release kube-prometheus-stack to v69 (#2646) :: renovate[bot]
- [`111ba26a`](http://github.com/seleniumhq/docker-selenium/commit/111ba26a70018ed452b92c615cbd7ae5c8195dfc) - K8s: Default Node register period is longer with a short cycle (#2662) :: Viet Nguyen Duc
- [`0a5b6ece`](http://github.com/seleniumhq/docker-selenium/commit/0a5b6ece0fda42a25fac67c7da07ac4aad1b13db) - K8s: Improve Node checks for liveness probe and preStop hook (#2661) :: Viet Nguyen Duc
- [`9fa52f19`](http://github.com/seleniumhq/docker-selenium/commit/9fa52f19f990de1aab69860748b9f23b2c29355d) - chore(deps): update helm release kube-prometheus-stack to v68.5.0 (#2645) :: renovate[bot]
- [`68cafe0f`](http://github.com/seleniumhq/docker-selenium/commit/68cafe0f67fc14018c6e23d82241569ca9506893) - chore(deps): update helm release kube-prometheus-stack to v68.4.5 (#2641) :: renovate[bot]
- [`3f544507`](http://github.com/seleniumhq/docker-selenium/commit/3f544507ab3c35b314474fce57d6a8d863c852d0) - [ci] Update chart 0.39.2 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.39.2

- Chart is using image tag 4.28.1-20250202
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.13,v1.30.9,v1.31.5,v1.32.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250202
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Added
- [`c30ae198`](http://github.com/seleniumhq/docker-selenium/commit/c30ae198207a5997848065cfbf779bce9a42f423) - feat: Deploy Node/Standalone Firefox browser version from v98 to v134 (#2632) :: Viet Nguyen Duc
- [`7f75dd06`](http://github.com/seleniumhq/docker-selenium/commit/7f75dd0607a506668b6c1ff6de71674d1c943dcb) - feat: Deploy Node/Standalone Chrome browser version from v97 to v109 on top of Grid 4.28.1 (#2626) :: Viet Nguyen Duc
- [`3ac17b96`](http://github.com/seleniumhq/docker-selenium/commit/3ac17b965985ac132ce83cc62ee49744f92cb030) - feat: Release Node/Standalone Chrome browser version from v110 to v131 on top of Grid 4.28.1 (#2621) :: Viet Nguyen Duc
- [`a7b58a4d`](http://github.com/seleniumhq/docker-selenium/commit/a7b58a4dca01116547459442067e910fdb23a280) - feat: added nodeSelector for keda patch pods (#2618) :: Amar Deep Singh

### Changed
- [`ad807bf3`](http://github.com/seleniumhq/docker-selenium/commit/ad807bf32d267cd566c25b531c9822f77bc0ea92) - [ci] Update tag 4.28.1-20250202 in docs and files :: Selenium CI Bot
- [`41f690aa`](http://github.com/seleniumhq/docker-selenium/commit/41f690aa623fa5ea231fb469db07af1136a099e1) - chore(deps): update helm release kube-prometheus-stack to v68.4.4 (#2630) :: renovate[bot]
- [`96453331`](http://github.com/seleniumhq/docker-selenium/commit/96453331fdcd98a444c92d26af5a6fb55993a160) - chore(deps): update helm release kube-prometheus-stack to v68.4.3 (#2622) :: renovate[bot]
- [`1f167b93`](http://github.com/seleniumhq/docker-selenium/commit/1f167b9379b6fe07414d1b8492e1a0995a25baf8) - Update Helm release kube-prometheus-stack to v68.4.0 (#2619) :: renovate[bot]
- [`e461dc8d`](http://github.com/seleniumhq/docker-selenium/commit/e461dc8d7c07b7a0aded7e6ccce8e2f1371478db) - Update Helm release kube-prometheus-stack to v68.3.2 (#2613) :: renovate[bot]
- [`04bb9cd9`](http://github.com/seleniumhq/docker-selenium/commit/04bb9cd9fe144215b66bf66080bbc2c366a1ce3b) - [ci] Update chart 0.39.1 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.39.1

- Chart is using image tag 4.28.1-20250123
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.13,v1.30.9,v1.31.5,v1.32.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250123
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Changed
- [`a233e6ef`](http://github.com/seleniumhq/docker-selenium/commit/a233e6efcbcf923f7608352f1a4e89931d3032c1) - [ci] Update tag 4.28.1-20250123 in docs and files :: Selenium CI Bot
- [`0ffbb8e0`](http://github.com/seleniumhq/docker-selenium/commit/0ffbb8e026e2a46be8a08be912fc04496a78f6a5) - [ci] Update chart 0.39.0 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.39.0

- Chart is using image tag 4.28.0-20250120
- Chart is tested on Kubernetes versions: v1.26.15,v1.27.16,v1.28.15,v1.29.13,v1.30.9,v1.31.5,v1.32.1
- Chart is tested on container runtime Docker versions: 26.1.4,27.4.1
- Chart is tested on Helm versions: v3.11.3,v3.12.3,v3.13.3,v3.14.3,v3.15.4,v3.16.4,v3.17.0
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250120
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Changed
- [`6cf49815`](http://github.com/seleniumhq/docker-selenium/commit/6cf498159d8e30195a2be67faa8f20b16e25a644) - [ci] Update tag 4.28.0-20250120 in docs and files :: Selenium CI Bot
- [`dd1731da`](http://github.com/seleniumhq/docker-selenium/commit/dd1731dab3f591e69717ecbc9e7b8f3b62740514) - Enable passing securityContext to initContainers in the Helm chart (#2607) :: Oskar Budziosz
- [`ee5e6581`](http://github.com/seleniumhq/docker-selenium/commit/ee5e6581fd93f4f72dfecb32c0e7c5ffb0c8d351) - Update Helm release kube-prometheus-stack to v68.3.0 (#2604) :: renovate[bot]
- [`e9c4c3df`](http://github.com/seleniumhq/docker-selenium/commit/e9c4c3df899642fba55bcb5c3c75a0ba20fff078) - Update Helm release kube-prometheus-stack to v68.2.2 (#2601) :: renovate[bot]
- [`d1ebdcfc`](http://github.com/seleniumhq/docker-selenium/commit/d1ebdcfc973c52b6ec7a0e3b4d570d98466f109c) - Update Helm release kube-prometheus-stack to v68.2.1 (#2597) :: renovate[bot]
- [`e10551de`](http://github.com/seleniumhq/docker-selenium/commit/e10551dea07751a031aff7c4fb775eca496a901e) - K8s: Allow adjutment of component replica count (#2600) :: joshfng
- [`2b2c9e02`](http://github.com/seleniumhq/docker-selenium/commit/2b2c9e0221511d8cdb4c937518abdbd78c6688fe) - [ci] Update chart 0.38.5 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.38.5

- Chart is using image tag 4.27.0-20250101
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.12, v1.30.8, v1.31.4, 
- Chart is tested on container runtime Docker versions: 26.1.4, 26.1.4, 26.1.4, 26.1.4, 26.1.4, 26.1.4, 27.4.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.4, 
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1-selenium-grid-20250101
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

### Changed
- [`bd0581df`](http://github.com/seleniumhq/docker-selenium/commit/bd0581dfe475cd406f1e3f4efb9fc8ae301d0a6a) - [docs] Update list of chart configs :: Viet Nguyen Duc
- [`1dedde79`](http://github.com/seleniumhq/docker-selenium/commit/1dedde7998eafaf2591cdf278e33b0e608b680c1) - K8s: Update KEDA patch version in default chart :: Viet Nguyen Duc
- [`a1950776`](http://github.com/seleniumhq/docker-selenium/commit/a195077697ccc36cb387f56d1ca23e5786710e42) - K8s: Fix chart template for relay node (#2594) :: Viet Nguyen Duc
- [`2130c340`](http://github.com/seleniumhq/docker-selenium/commit/2130c3401f782f446415182cbc51591465b67f94) - K8s: Update default component ConfigMap and resources limits (#2596) :: Viet Nguyen Duc
- [`9ab8d6dd`](http://github.com/seleniumhq/docker-selenium/commit/9ab8d6dda3e615de6bc618703c145c4e280e9267) - [docs] Add a tip to get started with Helm chart :: Viet Nguyen Duc
- [`7a51fd2b`](http://github.com/seleniumhq/docker-selenium/commit/7a51fd2b1c54bba34939f9c41314484904f8202b) - K8s: Update template for service configs (#2593) :: Viet Nguyen Duc
- [`7cbd6379`](http://github.com/seleniumhq/docker-selenium/commit/7cbd637963bd887e2055b4862c513736f3d0e38d) - K8s: Remove .svc.cluster.local from component host using service name (#2591) :: Viet Nguyen Duc
- [`f692a3c9`](http://github.com/seleniumhq/docker-selenium/commit/f692a3c9298466be1ab78baef983a3496620bbb2) - Update Helm release postgresql to v16.4.1 (#2579) :: renovate[bot]
- [`92841c54`](http://github.com/seleniumhq/docker-selenium/commit/92841c54ae8a487c5b9fd06decc19ba929915119) - Update Helm release kube-prometheus-stack to v68 (#2581) :: renovate[bot]
- [`6423b485`](http://github.com/seleniumhq/docker-selenium/commit/6423b485c0d03bf9ae6e4e9b556846ba684be6cc) - [Helm Chart] only add annotations stanza if they are annotations to add  (#2580) :: AvivGuiser
- [`93034dc3`](http://github.com/seleniumhq/docker-selenium/commit/93034dc36eadf2d7c89a1193d15a38665cb52dce) - Update Helm release redis to v20.6.2 (#2570) :: renovate[bot]
- [`5eeb9c08`](http://github.com/seleniumhq/docker-selenium/commit/5eeb9c0868442b3ae96147151bbb98bf5ddec003) - Update Helm release kube-prometheus-stack to v67.10.0 (#2576) :: renovate[bot]
- [`e0c3beba`](http://github.com/seleniumhq/docker-selenium/commit/e0c3bebad584184207308facd71aabd0142aedca) - K8s: Bump KEDA patch version (#2575) :: Viet Nguyen Duc
- [`2d3c355e`](http://github.com/seleniumhq/docker-selenium/commit/2d3c355e859a34796ed70824b923023e2f7c8e66) - Update Helm release kube-prometheus-stack to v67.9.0 (#2567) :: renovate[bot]
- [`d99871d9`](http://github.com/seleniumhq/docker-selenium/commit/d99871d9936f7fd6edf2aef938bdf718f7f56d0c) - Update Helm release kube-prometheus-stack to v67.8.0 (#2561) :: renovate[bot]
- [`1666105f`](http://github.com/seleniumhq/docker-selenium/commit/1666105f1b885bdf097deb6b71500eae3a9440d6) - [ci] Update chart 0.38.4 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.38.4

- Chart is using image tag 4.27.0-20250101
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.3.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.3, 
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1

### Changed
- [`d6333285`](http://github.com/seleniumhq/docker-selenium/commit/d63332853af9d75f4b15b441a435820072a23f35) - K8s: Release Helm chart 0.38.4 :: Viet Nguyen Duc
- [`5e7cd22a`](http://github.com/seleniumhq/docker-selenium/commit/5e7cd22a5abe1f1fcaf73332cd6779552021c464) - Update Helm release kube-prometheus-stack to v67.7.0 (#2557) :: renovate[bot]
- [`89b53515`](http://github.com/seleniumhq/docker-selenium/commit/89b53515fed54d0dbeb25e884726944a022429de) - K8s: Optimize template syntax without using default function :: Viet Nguyen Duc
- [`d3441094`](http://github.com/seleniumhq/docker-selenium/commit/d344109467116dc7c03392bbb4173b424227e2b6) - Update Helm release kube-prometheus-stack to v67.6.0 (#2554) :: renovate[bot]
- [`0654a586`](http://github.com/seleniumhq/docker-selenium/commit/0654a58636450c8bfa266534ad3876be7c628ad7) - Update Helm release postgresql to v16.3.5 (#2555) :: renovate[bot]
- [`da7612bf`](http://github.com/seleniumhq/docker-selenium/commit/da7612bf67a873182dcedc5d277eab2cc8b48600) - K8s: Node template handle `hpa.platformName` different with default in `values.yaml` :: Viet Nguyen Duc
- [`dce68319`](http://github.com/seleniumhq/docker-selenium/commit/dce683196d5f9f6a4f198fb5ff5ca6e9d93242bf) - K8s: Correct typo in values file `multiple-nodes-platform.yaml` :: Viet Nguyen Duc
- [`ab8e5195`](http://github.com/seleniumhq/docker-selenium/commit/ab8e5195e371fb38a7c61c5c1d2e4bf96fa9f6b2) - [ci] Update chart 0.38.3 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.38.3

- Chart is using image tag 4.27.0-20250101
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.3.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.3, 
- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1

### Changed
- [`f353914d`](http://github.com/seleniumhq/docker-selenium/commit/f353914db44470765311f2a42f302bf935e7428d) - [ci] Update tag 4.27.0-20250101 in docs and files :: Selenium CI Bot
- [`39027998`](http://github.com/seleniumhq/docker-selenium/commit/39027998f922a15e5bb97eb6773eb484e1518b58) - Docker: Collect JVM heap dump in case server run into error (#2546) :: Viet Nguyen Duc
- [`7d6ddb77`](http://github.com/seleniumhq/docker-selenium/commit/7d6ddb778549f2c366622d9e944d9355446b1b73) - K8s: Allow extra data set to EventBus and Node configmap (#2545) :: Viet Nguyen Duc
- [`bd7876e0`](http://github.com/seleniumhq/docker-selenium/commit/bd7876e0f3a66a184af9318ce9c10969307e184b) - Update Helm release kube-prometheus-stack to v67.5.0 (#2533) :: renovate[bot]
- [`bff83697`](http://github.com/seleniumhq/docker-selenium/commit/bff83697c1479889cae704c064d51ecd07541e0a) - Update Helm release postgresql to v16.3.4 (#2532) :: renovate[bot]
- [`c10b3d27`](http://github.com/seleniumhq/docker-selenium/commit/c10b3d2782a7a3ffa243000db72e8f91798d805d) - Update Helm release ingress-nginx to v4.12.0 (#2544) :: renovate[bot]
- [`6f25d806`](http://github.com/seleniumhq/docker-selenium/commit/6f25d806d43554bd6d98619ec0d7e21dd1eadfba) - K8s: Add default values for multiple nodes platform and version (#2543) :: Viet Nguyen Duc
- [`d01680cb`](http://github.com/seleniumhq/docker-selenium/commit/d01680cba3feb3d050d9ff667aaa9816fca8e33a) - K8s: Update config `components.subPath` to `components.router.subPath` :: Viet Nguyen Duc
- [`325307ac`](http://github.com/seleniumhq/docker-selenium/commit/325307ac5fa14569f4110b30dcfdda68b9989368) - K8s: Configs extraEnvironmentVariables, extraEnvFrom in each distributed component :: Viet Nguyen Duc
- [`2d80c880`](http://github.com/seleniumhq/docker-selenium/commit/2d80c8805d5141d3b382f32271d3bf032b0c1120) - [ci] Update chart 0.38.2 changelog :: Selenium CI Bot

## :heavy_check_mark: selenium-grid-0.38.2

- Chart is using image tag 4.27.0-20241225
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.3.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.3, 

### Changed
- [`53a78a72`](http://github.com/seleniumhq/docker-selenium/commit/53a78a7223937a6bc9ec2bb4c327016426c50b5f) - [ci] Update tag 4.27.0-20241225 in docs and files :: Selenium CI Bot
- [`dddbebbf`](http://github.com/seleniumhq/docker-selenium/commit/dddbebbf74243ea3c96e59165c06d4877fc03a7f) - K8s: Config clusterIP, externalName to svc of Hub, Router, EventBus :: Viet Nguyen Duc
- [`08a9ea1d`](http://github.com/seleniumhq/docker-selenium/commit/08a9ea1df0bb635d50ff7a5d25122921f4ad8b78) - K8s: Node preStop rely on local PID :: Viet Nguyen Duc
- [`d4ed4ef2`](http://github.com/seleniumhq/docker-selenium/commit/d4ed4ef27a95c4b87d90a6043141f163ffbb05af) - [ci] Update workflow for secrets inherit :: Viet Nguyen Duc
- [`c91807ba`](http://github.com/seleniumhq/docker-selenium/commit/c91807bae149834d1b0942363ca9de27187145ae) - Update Helm release kube-prometheus-stack to v67.2.1 (#2518) :: renovate[bot]
- [`ffb182d0`](http://github.com/seleniumhq/docker-selenium/commit/ffb182d0db500d2c7e9025623222faeef145c33d) - Update Helm release postgresql to v16.3.3 (#2523) :: renovate[bot]
- [`a8413090`](http://github.com/seleniumhq/docker-selenium/commit/a84130906c1c97c619f5e35e83ca0e33b05aa65e) - Update Helm release redis to v20.6.1 (#2524) :: renovate[bot]
- [`f5679f51`](http://github.com/seleniumhq/docker-selenium/commit/f5679f5165cc4999ab2d254d00814c89c7dd6f83) - Docker: Improve the video recording container graceful shutdown (#2527) :: Viet Nguyen Duc
- [`d86d252f`](http://github.com/seleniumhq/docker-selenium/commit/d86d252f6d4b92c57acb05fed52be87741f205b9) -  K8s: Autoscaling using KEDA core 2.16.1 (#2531) :: Viet Nguyen Duc
- [`6f90ecba`](http://github.com/seleniumhq/docker-selenium/commit/6f90ecbacc651f4775ac9b6d848a86f698dbbddb) - K8s: Selenium Grid in case multiple scaler triggers are activate (#2515) :: Viet Nguyen Duc
- [`2741b810`](http://github.com/seleniumhq/docker-selenium/commit/2741b81098e1b516349e64e830953d2c3a9189f9) - Update Helm release postgresql to v16.3.2 (#2516) :: renovate[bot]
- [`d4f67f0f`](http://github.com/seleniumhq/docker-selenium/commit/d4f67f0fbb04c62431a094cfabd538ba753867f5) - Update Helm release postgresql to v16.2.5 (#2496) :: renovate[bot]
- [`6e322d14`](http://github.com/seleniumhq/docker-selenium/commit/6e322d149a5e07978efe1ea3d9ee17dc8b8a6eeb) - Update Helm release redis to v20.6.0 (#2514) :: renovate[bot]
- [`732b3756`](http://github.com/seleniumhq/docker-selenium/commit/732b37564d6713f93cfc7e9d1fc4367c1b895889) - Update Helm release kube-prometheus-stack to v67.2.0 (#2513) :: renovate[bot]
- [`033b65b7`](http://github.com/seleniumhq/docker-selenium/commit/033b65b70c7c4329732511b2906cdbc427f0efc0) - Update Helm release redis to v20.4.1 (#2499) :: renovate[bot]
- [`5369ab1c`](http://github.com/seleniumhq/docker-selenium/commit/5369ab1cfea5dd54d5fcecfaa06788614635bfaa) - Update Helm release kube-prometheus-stack to v67 (#2510) :: renovate[bot]
- [`d66ac528`](http://github.com/seleniumhq/docker-selenium/commit/d66ac5283a06d293af0ee140cac8867a3b39ec46) - Build static FFmpeg and copy binary to Node base (#2468) :: Viet Nguyen Duc
- [`36d98e98`](http://github.com/seleniumhq/docker-selenium/commit/36d98e988b9427f619db426a184b909a41992784) - Correct kubectl cli params in keda patch job (#2501) :: jbolsens-legion
- [`bd948709`](http://github.com/seleniumhq/docker-selenium/commit/bd9487096046548b37b8515a3236e7fa87971ecf) - Update chart 0.38.1 changelog :: Viet Nguyen Duc

- Chart is tested autoscaling capabilities with KEDA image tag: 2.16.1

## :heavy_check_mark: selenium-grid-0.38.1

- Chart is using image tag 4.27.0-20241204
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.3.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.3, 

### Changed
- [`739d7e8c`](http://github.com/seleniumhq/docker-selenium/commit/739d7e8c5305987a814cd670589e68c7dce7329e) - Update tag 4.27.0-20241204 in docs and files :: Selenium CI Bot
- [`26c177da`](http://github.com/seleniumhq/docker-selenium/commit/26c177dadd7800fae835c921d4d1653b4a60b27f) - chore(deps): update Helm release postgresql to v16.2.4 (#2493) :: renovate[bot]
- [`49c4a2fd`](http://github.com/seleniumhq/docker-selenium/commit/49c4a2fd7e800d809fe3821b86220dc5793c0b7e) - K8s: Add configs for sessions external datastore (#2491) :: Viet Nguyen Duc
- [`7e6b9b30`](http://github.com/seleniumhq/docker-selenium/commit/7e6b9b3033646156299935cae3bb4b56f1da7270) - K8s: Add test results for Grid autoscaling with KEDA (#2490) :: Viet Nguyen Duc
- [`cf0c839a`](http://github.com/seleniumhq/docker-selenium/commit/cf0c839ab05a6ae958ef2ef813c6d9aaddbf65d7) - K8s: regression issue on template for nodes service.enabled (#2484) :: Viet Nguyen Duc
- [`a4c352d7`](http://github.com/seleniumhq/docker-selenium/commit/a4c352d7e024c521946ac887bd3e305add91a59b) - chore(deps): Update Helm release kube-prometheus-stack to v66.3.0 (#2480) :: renovate[bot]
- [`689a62d9`](http://github.com/seleniumhq/docker-selenium/commit/689a62d96a6d558e06843ed36970dbece497fb6b) - chore(deps): Update Helm release jaeger to v3.3.3 (#2483) :: renovate[bot]
- [`fcfb16ee`](http://github.com/seleniumhq/docker-selenium/commit/fcfb16eea52e412dffdcb756c3bac78681ad2e71) - Update chart 0.38.0 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.38.0

- Chart is using image tag 4.27.0-20241127
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.3.1, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.3, 

### Changed
- [`c5e10a7c`](http://github.com/seleniumhq/docker-selenium/commit/c5e10a7c7f8e6538f5bee7079a7d6f7e0587368b) - Update tag 4.27.0-20241127 in docs and files :: Selenium CI Bot
- [`4e202839`](http://github.com/seleniumhq/docker-selenium/commit/4e202839343e5671f420a2d4af3dcc03749d732e) - [ci] Update command to get host ip in runners :: Viet Nguyen Duc
- [`60603842`](http://github.com/seleniumhq/docker-selenium/commit/606038425ba721ba57a1ae9038c187cb2490e9fd) - chore(deps): update helm release kube-prometheus-stack to v66 (#2461) :: renovate[bot]
- [`7727b6d8`](http://github.com/seleniumhq/docker-selenium/commit/7727b6d8881728d4cc9f37d173646307329fd3c2) - K8s: Use KEDA patch image tag for scaler implementation preview (#2477) :: Viet Nguyen Duc
- [`bea0769a`](http://github.com/seleniumhq/docker-selenium/commit/bea0769a998216d4a0c2a82b2a6e19139596ceca) - K8s: Multiple nodes browser in Helm configs (#2475) :: Viet Nguyen Duc
- [`3dddb7d0`](http://github.com/seleniumhq/docker-selenium/commit/3dddb7d0027adbf56b9e287888ec05f309d04c07) - K8s: Update ScaledJob scaling strategy to `eager` as default (#2466) :: Viet Nguyen Duc
- [`33471fe8`](http://github.com/seleniumhq/docker-selenium/commit/33471fe8e1aa48efdf52937262b2bfed86ef1e07) - K8s: Deployment scale metricType should be Value instead of AverageValue (#2465) :: Viet Nguyen Duc
- [`bf73ae98`](http://github.com/seleniumhq/docker-selenium/commit/bf73ae985f20b8363c3c46d414965a64036ef390) - Update chart 0.37.1 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.37.1

- Chart is using image tag 4.26.0-20241101
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.11.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Changed
- [`fc81fd05`](http://github.com/seleniumhq/docker-selenium/commit/fc81fd05ac7f5b51b91e089d4e189c5b2ea5e720) - Release chart 0.37.1 :: Viet Nguyen Duc
- [`82350ba8`](http://github.com/seleniumhq/docker-selenium/commit/82350ba80a959464c74ecf6582bea2ac97eca913) - Update chart configuration table :: Selenium CI Bot
- [`edfe8a30`](http://github.com/seleniumhq/docker-selenium/commit/edfe8a3020db5beeb1d7f11a0b45194aae3fe6d3) - chore(deps): update helm release kube-prometheus-stack to v65.8.1 (#2428) :: renovate[bot]
- [`a1887055`](http://github.com/seleniumhq/docker-selenium/commit/a1887055c59b200b8ffd5f46a02809fc6be9dc25) - chore(deps): update helm release jaeger to v3.3.2 (#2455) :: renovate[bot]
- [`e0a7d63b`](http://github.com/seleniumhq/docker-selenium/commit/e0a7d63b75c7540a9447a8008feb164e715fcb3e) - chore(deps): update helm release keda to v2.16.0 (#2459) :: renovate[bot]
- [`06663919`](http://github.com/seleniumhq/docker-selenium/commit/06663919defd859345c7b5d942106405453d30cf) - Update chart 0.37.0 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.37.0

- Chart is using image tag 4.26.0-20241101
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Changed
- [`6ce652ba`](http://github.com/seleniumhq/docker-selenium/commit/6ce652ba6ec1108d7ce05b4af5ea140d73873b59) - Update tag 4.26.0-20241101 in docs and files :: Selenium CI Bot
- [`b41b6271`](http://github.com/seleniumhq/docker-selenium/commit/b41b62713a67488634861a52c8c6444e1b6beb71) - chart: set job scaling strategy to accurate by default :: Viet Nguyen Duc
- [`a862efa3`](http://github.com/seleniumhq/docker-selenium/commit/a862efa3026a5aba100721ff83d858f67a1eafc7) - chart: Add templates for relay node (#2453) :: Viet Nguyen Duc
- [`1fdc58bf`](http://github.com/seleniumhq/docker-selenium/commit/1fdc58bf072b7a276d8f33639a681f1d1c7cd3bc) - chart: Allow overwrite config videoRecorder in each node (#2445) :: Viet Nguyen Duc
- [`3290a305`](http://github.com/seleniumhq/docker-selenium/commit/3290a305c0d122ce90d5301b96f46dc0728e33e8) - Update chart 0.36.5 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.5

- Chart is using image tag 4.25.0-20241024
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.15, v1.29.10, v1.30.6, v1.31.2, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Changed
- [`653af3e2`](http://github.com/seleniumhq/docker-selenium/commit/653af3e22860eea2fd236c8289c874ba15837a98) - Update tag 4.25.0-20241024 in docs and files :: Selenium CI Bot
- [`42a7ecdb`](http://github.com/seleniumhq/docker-selenium/commit/42a7ecdbc745441309a66eb079d74a910276bb56) - Update log timestamp in custom scripts align with supervisord (#2441) :: Viet Nguyen Duc

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.4

- Chart is using image tag 4.25.0-20241010
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.14, v1.29.9, v1.30.5, v1.31.1, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Fixed
- [`ec01d2f5`](http://github.com/seleniumhq/docker-selenium/commit/ec01d2f5fe22a3ba0932b4e095a083585abbc134) - fix: bash avoiding newline when Base64 encoding a long string (#2437) :: Viet Nguyen Duc

### Changed
- [`022c35f6`](http://github.com/seleniumhq/docker-selenium/commit/022c35f68f825540f6cde72f5c0d379b54156e29) - chore(deps): update helm release keda to v2.15.2 (#2433) :: renovate[bot]
- [`36ba1870`](http://github.com/seleniumhq/docker-selenium/commit/36ba1870f113aba414a08dd1211d5fc5409ff370) - Update chart 0.36.3 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.3

- Chart is using image tag 4.25.0-20241010
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.14, v1.29.9, v1.30.5, v1.31.1, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Changed
- [`b86c952c`](http://github.com/seleniumhq/docker-selenium/commit/b86c952c5c450ad96eb9eae336aa6ab5eebf3b99) - chart(update): template remove redundant newlines :: Viet Nguyen Duc
- [`e7ca1dcd`](http://github.com/seleniumhq/docker-selenium/commit/e7ca1dcd85545ea5ae920634be671d1f48e885a0) - chart(update): Node deployment replicas use minReplicaCount in autoscaling (#2430) :: Viet Nguyen Duc
- [`94da26e6`](http://github.com/seleniumhq/docker-selenium/commit/94da26e6cc421d781cb0456497fa852b5cbb79fe) - chart(update): use podIP in all components server host (#2429) :: Viet Nguyen Duc
- [`5802c323`](http://github.com/seleniumhq/docker-selenium/commit/5802c323459957f7032065a1fee84703d7ec0150) - Update chart 0.36.2 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.2

- Chart is using image tag 4.25.0-20241010
- Chart is tested on Kubernetes versions: v1.25.16, v1.26.15, v1.27.16, v1.28.14, v1.29.9, v1.30.5, v1.31.1, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.3, v3.15.4, v3.16.1, 

### Changed
- [`72387472`](http://github.com/seleniumhq/docker-selenium/commit/723874729ab63018fc0405490a6f3313ca575ddd) - Update tag 4.25.0-20241010 in docs and files :: Selenium CI Bot
- [`c3ad0995`](http://github.com/seleniumhq/docker-selenium/commit/c3ad0995c9288c39e62e91978ab96c0b253753bc) - Update chart configuration table :: Selenium CI Bot
- [`be2a920f`](http://github.com/seleniumhq/docker-selenium/commit/be2a920f723d75ca4725e7b22b94324682b04b78) - chore(deps): update helm release kube-prometheus-stack to v65 (#2422) :: renovate[bot]
- [`ef2c6c49`](http://github.com/seleniumhq/docker-selenium/commit/ef2c6c493ca41b3f2760b93a5678725bdcccd808) - chore(deps): update helm release ingress-nginx to v4.11.3 (#2424) :: renovate[bot]
- [`ea7b913c`](http://github.com/seleniumhq/docker-selenium/commit/ea7b913c8d58ffcff0923c2ff128b4ccf135b82e) - chart(feat): add graphql metrics exporter for monitoring (#2425) :: Viet Nguyen Duc
- [`1a9aa386`](http://github.com/seleniumhq/docker-selenium/commit/1a9aa386352050a357abdc5cfbbcf5ea01cc1e71) - chart(fix): node.lifecycle not being rendered from values file (#2420) :: Bruno Brito
- [`dedd69b1`](http://github.com/seleniumhq/docker-selenium/commit/dedd69b113dfae966fd58b79338a136f40fea8fc) - Update chart 0.36.1 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.1

- Chart is using image tag 4.25.0-20240922
- Chart is tested on Kubernetes versions: v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, v1.31.0, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Changed
- [`8466588e`](http://github.com/seleniumhq/docker-selenium/commit/8466588e4023ec844bafa18252f7f932d7767621) - chart(fix): `basicAuth.embeddedUrl` in GraphQL endpoint for old scaler compatible (#2408) :: Viet Nguyen Duc
- [`5a3f1e9e`](http://github.com/seleniumhq/docker-selenium/commit/5a3f1e9e821f8823a4ccfea48628a6ba02cce776) - Update base image ubuntu:noble-20240827.1 :: Viet Nguyen Duc
- [`ff5b2489`](http://github.com/seleniumhq/docker-selenium/commit/ff5b2489e8c97a688d2d1ef18b27a67a0f74370f) - chore(deps): update helm release kube-prometheus-stack to v62.7.0 (#2397) :: renovate[bot]
- [`75b59cfb`](http://github.com/seleniumhq/docker-selenium/commit/75b59cfb56190c0f12e27ec48fcc9e9f06184523) - chore(deps): update helm release jaeger to v3.3.1 (#2393) :: renovate[bot]
- [`87111047`](http://github.com/seleniumhq/docker-selenium/commit/871110478dd18a260e58f6e56e8192e12e32b1af) - Update chart 0.36.0 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

## :heavy_check_mark: selenium-grid-0.36.0

- Chart is using image tag 4.25.0-20240922
- Chart is tested on Kubernetes versions: v1.26.15, v1.27.16, v1.28.13, v1.29.8, v1.30.4, v1.31.0, 
- Chart is tested on container runtime Docker versions: 24.0.9, 24.0.9, 24.0.9, 25.0.5, 26.1.4, 27.2.0, 
- Chart is tested on Helm versions: v3.10.3, v3.11.3, v3.12.3, v3.13.3, v3.14.4, v3.15.4, 

### Fixed
- [`65933cdc`](http://github.com/seleniumhq/docker-selenium/commit/65933cdcfff19dd887767c7925740e95adf2d835) - fix: video container wait capabilities fully before extracting details :: Viet Nguyen Duc

### Changed
- [`ba687ae2`](http://github.com/seleniumhq/docker-selenium/commit/ba687ae2ae02afc4be9770dac3def1ad09d939bb) - Update tag 4.25.0-20240922 in docs and files :: Selenium CI Bot
- [`12868dd0`](http://github.com/seleniumhq/docker-selenium/commit/12868dd0e07ebf348bd5e46c6aed2810f5d89fd7) - chart: add config key to disable resource creation :: Viet Nguyen Duc
- [`0ac93a9c`](http://github.com/seleniumhq/docker-selenium/commit/0ac93a9cf3f40c040b6f271ce6f599609c1419f2) - Experimental: Selenium Grid scaler with different nodeMaxSessions per node (#2402) :: Viet Nguyen Duc
- [`6c4f76e7`](http://github.com/seleniumhq/docker-selenium/commit/6c4f76e7547d93272bfbadee55b233e7b49e37d4) - chart(add): Grid scaler use trigger auth to secure GraphQL endpoint (#2401) :: Viet Nguyen Duc
- [`2af6166d`](http://github.com/seleniumhq/docker-selenium/commit/2af6166d263ab5d74be4178aa882a00f4aa9acf1) - Experimental: Selenium Grid scaler in K8s implementation preview (#2400) :: Viet Nguyen Duc
- [`e27f6edb`](http://github.com/seleniumhq/docker-selenium/commit/e27f6edbfa0b31464bdeae3a772dc01c4725b8b5) - chart(update): replace another mininal kubectl container for patch job :: Viet Nguyen Duc
- [`35fafaf2`](http://github.com/seleniumhq/docker-selenium/commit/35fafaf2e22601b9553ba4c9ad90196fc54b2d76) - Update _helpers.tpl to adress missing resource limits in pre-puller init containers for firefox,edge,... (#2399) :: Markus Kopp
- [`7dc9f187`](http://github.com/seleniumhq/docker-selenium/commit/7dc9f187e41ce8e892696fee148b5d3eb7aef86e) - chart: protect resources naming against .Release.Nam contains dots. from ArgoCD :: Viet Nguyen Duc
- [`a545d08e`](http://github.com/seleniumhq/docker-selenium/commit/a545d08ee8aea90bb3595744c6dc7e4a872cac4b) - Update chart 0.35.2 changelog [skip ci] :: Selenium CI Bot

### Experimental
- Selenium Grid Scaler implementation preview. [README](https://github.com/seleniumhq/docker-selenium/tree/trunk/.keda/README.md)

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
