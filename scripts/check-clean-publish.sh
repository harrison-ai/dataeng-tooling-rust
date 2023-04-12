#!/usr/bin/env bash
#
# Check that we can cleanly publish the current git HEAD to github container registry.
# This will fail unless we're on a clean checkout of `main`.
#

set -e

# We only ever publish from a clean checkout of `main`.
if git diff --exit-code > /dev/null; then true; else 
    echo "Refusing to publish from a working dir with unstaged changes"
    exit 1
fi
if git diff --cached --exit-code > /dev/null; then true; else
    echo "Refusing to publish from a working dir with uncommited changes"
    exit 1
fi
if [ `git branch --show-current` != "main" ]; then
    echo "Refusing to publish from a branch other than 'main'"
    exit 1
fi
