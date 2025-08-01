#!/bin/bash

# Local testing script for the bcftools Docker container

set -e

GITHUB_ORG="${GITHUB_ORG:-mamanambiya}"
GITHUB_REPO="${GITHUB_REPO:-simple-bcftools-tools-wdl}"
CONTAINER_TAG="${CONTAINER_TAG:-latest}"

IMAGE="ghcr.io/${GITHUB_ORG}/${GITHUB_REPO}/bcftools-azure:${CONTAINER_TAG}"

echo "Testing BCFtools Docker container locally"
echo "Image: ${IMAGE}"
echo "========================================="

# Build the container locally if needed
if [[ "$1" == "--build" ]]; then
    echo "Building container locally..."
    docker build -t ${IMAGE} -f docker/Dockerfile .
fi

# Test 1: Check bcftools version
echo -e "\nTest 1: BCFtools version"
docker run --rm ${IMAGE} bcftools --version

# Test 2: Check plot-vcfstats availability
echo -e "\nTest 2: Plot-vcfstats availability"
docker run --rm ${IMAGE} sh -c "which plot-vcfstats && echo 'plot-vcfstats is available'"

# Test 3: Check Python and dependencies
echo -e "\nTest 3: Python dependencies"
docker run --rm ${IMAGE} python3 -c "import matplotlib, numpy; print('Python dependencies OK')"

# Test 4: Run bcftools stats on test data (if available)
if [ -f "test/test.vcf.gz" ]; then
    echo -e "\nTest 4: Running bcftools stats on test data"
    docker run --rm -v $PWD:/data ${IMAGE} bcftools stats /data/test/test.vcf.gz
else
    echo -e "\nTest 4: Skipped (no test data found at test/test.vcf.gz)"
fi

# Test 5: Check multi-platform support
echo -e "\nTest 5: Container platform"
docker run --rm ${IMAGE} sh -c "uname -m && cat /etc/os-release | grep PRETTY_NAME"

echo -e "\n✅ All tests completed!"
