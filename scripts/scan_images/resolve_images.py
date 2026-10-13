#!/usr/bin/env python3
"""Work out which published images to scan for a given tag.

This was shell inside the workflow. It is Python because the shell version had a
quoting bug that made it silently match nothing: interpolating the tag forced the
grep pattern into double quotes, bash ate the backslash in ``\\$``, and ``$``
became an end-of-line anchor. The scan reported success having scanned zero
images. Anything that can fail silently and still look green belongs somewhere it
can be tested.

Two sources, and both matter:

* The ``Makefile`` says what this project *builds*. The Docker Hub namespace also
  holds long-retired repositories - node-opera, node-phantomjs, the -debug
  variants - which still carry a ``latest`` tag from years ago. Scanning those
  would report CVEs nobody is going to fix and burn Scout quota doing it.
* Docker Hub says what actually *exists*. A tag in the Makefile that was never
  pushed should be reported here, not turned into an opaque Scout failure.

So: take the Makefile's list, drop the upstream mirrors, and confirm against the
registry.
"""

import argparse
import json
import pathlib
import re
import sys
import urllib.error
import urllib.request

REPO_ROOT = pathlib.Path(__file__).resolve().parents[2]
MAKEFILE = REPO_ROOT / "Makefile"
HUB_API = "https://hub.docker.com/v2"

# Re-tags of upstream kedacore images, made by release_grid_scaler_*. A CVE in
# them is fixed by bumping KEDA_BASED_TAG, not by anything built here, so they
# are not this scan's business. keda-external-scaler is ours and is kept.
UPSTREAM_MIRRORS = {"keda", "keda-metrics-apiserver", "keda-admission-webhooks"}


def images_for_tag(makefile_text, tag):
    """Every image the Makefile publishes under `tag`, minus the upstream mirrors."""
    pattern = re.compile(r"\$\(NAME\)/([a-z0-9._-]+):" + re.escape(tag) + r"(?![a-z0-9._-])")
    found = set(pattern.findall(makefile_text))
    return sorted(found - UPSTREAM_MIRRORS)


def tag_exists(namespace, image, tag, opener=urllib.request.urlopen):
    try:
        opener(f"{HUB_API}/repositories/{namespace}/{image}/tags/{tag}/", timeout=30)
        return True
    except urllib.error.HTTPError as error:
        if error.code == 404:
            return False
        raise


def verify(images, namespace, tag, opener=urllib.request.urlopen):
    """(published, missing). Missing means the Makefile builds it but the tag is not there."""
    published, missing = [], []
    for image in images:
        try:
            (published if tag_exists(namespace, image, tag, opener) else missing).append(image)
        except Exception as error:  # noqa: BLE001 - a registry blip must not empty the matrix
            print(f"WARNING  {image}: could not check the registry ({error}); scanning anyway", file=sys.stderr)
            published.append(image)
    return published, missing


def main(argv=None):
    parser = argparse.ArgumentParser(description="Resolve the images to scan for a tag.")
    parser.add_argument("--tag", default="latest")
    parser.add_argument("--namespace", default="selenium")
    parser.add_argument("--images", default="", help="Explicit space or comma separated list, overrides the Makefile.")
    parser.add_argument("--verify", action="store_true", help="Drop images whose tag is absent from the registry.")
    parser.add_argument("--format", choices=["json", "lines"], default="json")
    args = parser.parse_args(argv)

    if args.images.strip():
        images = sorted({name for name in re.split(r"[,\s]+", args.images.strip()) if name})
    else:
        images = images_for_tag(MAKEFILE.read_text(), args.tag)

    if not images:
        print(f"No images found for tag {args.tag!r}. Check the Makefile or pass --images.", file=sys.stderr)
        return 1

    missing = []
    if args.verify:
        images, missing = verify(images, args.namespace, args.tag)

    for image in missing:
        print(f"WARNING  {args.namespace}/{image}:{args.tag} is built by the Makefile but not on the registry", file=sys.stderr)
    if not images:
        print(f"Every candidate image is missing the {args.tag!r} tag on the registry.", file=sys.stderr)
        return 1

    print(f"Resolved {len(images)} image(s) for :{args.tag}", file=sys.stderr)
    if args.format == "json":
        print(json.dumps(images))
    else:
        print("\n".join(images))
    return 0


if __name__ == "__main__":
    sys.exit(main())
