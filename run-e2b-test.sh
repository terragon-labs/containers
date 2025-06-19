#!/bin/bash

# Script to build the E2B Docker image and test bun/pnpm installation

set -e

echo "Building E2B Docker image..."
docker build -f e2b.Dockerfile -t e2b-package-managers .

echo -e "\nRunning package manager tests..."
docker run --rm \
  -v "$(pwd)/test-package-managers.sh:/test-package-managers.sh" \
  e2b-package-managers \
  bash -c "/test-package-managers.sh"

echo -e "\nTesting interactive commands..."
echo "Testing bun --help:"
docker run --rm e2b-package-managers bun --help | head -5

echo -e "\nTesting pnpm --help:"
docker run --rm e2b-package-managers pnpm --help | head -5

echo -e "\nAll tests completed successfully!"