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
make update_dockerhub_description DRY_RUN=true       # report what would change
make update_dockerhub_description                    # publish
```

| Command | Credentials | Network |
| --- | --- | --- |
| `make check_dockerhub_description` | None. | None. Parses the files and compares them against the `Makefile`. |
| `make update_dockerhub_description DRY_RUN=true` | `DOCKER_USERNAME` and `DOCKER_PASSWORD` must be **set**, but are not used — dummy values are fine. The dry run skips the login call and reads the current overviews from the public `GET` endpoint. | Yes, read-only. |
| `make update_dockerhub_description` | `DOCKER_USERNAME` and `DOCKER_PASSWORD` must be real. | Yes, reads and writes. |

Both `update_dockerhub_description` modes exit with `DOCKER_USERNAME and DOCKER_PASSWORD must be
set.` when either variable is missing, so export a placeholder before a dry run:

```bash
DOCKER_USERNAME=x DOCKER_PASSWORD=x make update_dockerhub_description DRY_RUN=true
```
