#!/bin/bash

NAMESPACE=${NAME:-selenium}
FILTER_IMAGE_TAG=${FILTER_IMAGE_TAG:-"*"}
OUTPUT_FILE=${OUTPUT_FILE:-"package_versions.txt"}

# List all Docker images matching tag
images=$(docker images --filter=reference=${NAMESPACE}'/*:'${FILTER_IMAGE_TAG} --format "{{.Repository}}:{{.Tag}}")

# Check if there are any images
if [ -z "$images" ]; then
  echo "No Docker images found."
  exit 1
fi

echo -n "" >${OUTPUT_FILE}
# Iterate through each image and generate SBOM
for image in $images; do
  echo "Generating SBOM for image: $image"
  echo "==================== $image ====================" >>${OUTPUT_FILE}
  docker sbom $image >>${OUTPUT_FILE}
  echo "" >>${OUTPUT_FILE}
done

echo "SBOM generation completed for all images."
