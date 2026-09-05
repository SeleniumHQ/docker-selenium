# Docker Hub image descriptions

Every file in this directory is the source of truth for one repository overview page on
[hub.docker.com/u/selenium](https://hub.docker.com/u/selenium). Edit them here, not in the Docker
Hub web UI — a change made in the UI is overwritten on the next release.

## Layout

The file name is the Docker Hub repository name. `standalone-chrome.md` publishes to
`selenium/standalone-chrome`.

```markdown
---
description: Selenium Grid in Standalone mode with Chrome
---
# Selenium Grid Standalone with Chrome

...
```

| Key | Meaning |
| --- | --- |
| `description` | The short description under the repository name. Maximum **100** characters. Required. |
| `footer` | Set to `false` to suppress the shared `_footer.md` trailer. Defaults to `true`. |

The body becomes the long overview, capped at **25 000** characters. `_footer.md` holds the
documentation and licence links shared by every page; edit it once to change them everywhere.

## Version numbers in the example blocks

Each description ends with an `### Example of a release ...` block showing the tag ladder. Those
blocks are written with placeholders, not real numbers:

```
e126989f151e        selenium/hub   <Major>
e126989f151e        selenium/hub   <Major>.<Minor>
e126989f151e        selenium/hub   <Major>.<Minor>.<Patch>
e126989f151e        selenium/hub   <Major>.<Minor>.<Patch>-<YYYYMMDD>
```

The real numbers live in the generated `_versions.json` and are substituted into the block when the
description is published, so the page on Docker Hub shows concrete tags while the Markdown here
never goes stale.

**Do not hand-edit the numbers into the Markdown.** `update_tag_in_docs_and_files.sh` rewrites only
an exact match of the previous release tag, so it can update `4.48.0-20260909` but not the bare
`4.48` or `4.48.0` beside it. Pinning them by hand produces blocks that contradict themselves after
the next release — "Grid Server 4.48.0, released on 20261010".

| Placeholder | Source |
| --- | --- |
| `<Major>`, `<Minor>`, `<Patch>`, `<YYYYMMDD>` | the release tag |
| `<BrowserMajor>`, `<BrowserMinor>`, `<DriverMajor>`, `<DriverMinor>`, `<GeckoDriverMajor>`, `<GeckoDriverMinor>` | `CHANGELOG/<version>/<browser>_<major>.md` |
| `<BrowserFullVersion>`, `<DriverFullVersion>` | chromium only, read from its published tags |

`_versions.json` is refreshed automatically in two places: the CHANGELOG pull request, where browser
versions change, and the release itself, where the Grid tag changes. To refresh it by hand:

```bash
make update_dockerhub_versions                          # needs network for chromium only
make update_dockerhub_versions GRID_TAG=4.49.0-20261010  # pin the Grid tag explicitly
```

If a placeholder has no value, publishing fails rather than putting `<Major>` on a public page.

## Publishing

| When | What happens |
| --- | --- |
| Pull request touching this directory | Descriptions are validated. No publish. |
| Push to `trunk` touching this directory | Published to Docker Hub. |
| A release (`deploy.yml`) | `update_tag_in_docs_and_files.sh` rewrites version tags here, then the descriptions are published. |
| Manual | The `Update Docker Hub descriptions` workflow, with an optional dry run. |

Adding a `$(NAME)/<image>` build to the `Makefile` without adding `<image>.md` here fails the
pull-request check, and vice versa.

## Locally

```bash
make check_dockerhub_description                     # validate; no network, no credentials
make test_dockerhub_description                      # unit tests; no network, no credentials
make update_dockerhub_versions                       # refresh _versions.json
make update_dockerhub_description DRY_RUN=true       # report what would change
make update_dockerhub_description                    # publish
```

| Command | Credentials | Network |
| --- | --- | --- |
| `make check_dockerhub_description` | None. | None. Parses the files and compares them against the `Makefile`. |
| `make update_dockerhub_description DRY_RUN=true` | `DOCKER_USERNAME` and `DOCKER_PASSWORD` must be **set**, but are not used — dummy values are fine. The dry run skips the login call and reads the current overviews from the public `GET` endpoint. | Yes, read-only. |
| `make update_dockerhub_description` | `DOCKER_USERNAME` and `DOCKER_PASSWORD` must be real. | Yes, reads and writes. |
| `make test_dockerhub_description` | None. | None. |
| `make update_dockerhub_versions` | None. | Yes, but only to read chromium's published tags. Everything else comes from `CHANGELOG/`. |

Both `update_dockerhub_description` modes exit with `DOCKER_USERNAME and DOCKER_PASSWORD must be
set.` when either variable is missing, so export a placeholder before a dry run:

```bash
DOCKER_USERNAME=x DOCKER_PASSWORD=x make update_dockerhub_description DRY_RUN=true
```
