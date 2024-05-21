#!/bin/bash

# For more information, see: https://github.com/devcontainers/cli/blob/main/docs/features/test.md

set -e

source dev-container-features-test-lib

check "plz --help" plz --help

reportResults
