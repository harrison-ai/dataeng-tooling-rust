#!/usr/bin/env bash
#
# Check that a version number has correctly increased.
# Called like:
#
#    ./scripts/check-increment.sh OLD NEW
#
# This script will exit successfully if the new version number is bigger
# than the old one.
#
# It's a bit weird and janky and fragile to do this comparison in shell
# (and suggestions of a better way are welcome!) but it makes it nice and
# easy and quick to run in CI, so here we are...

OLD_VERSION="${1-}"
NEW_VERSION="${2-}"

if [ -z "${OLD_VERSION}" ]; then
    echo "ERROR: please specify old version number as first argument" 1>&2
    exit 1
fi
if [ -z "${OLD_VERSION}" ]; then
    echo "ERROR: please specify new version number as second argument" 1>&2
    exit 1
fi

OLD_RUST_MAJOR_VERSION=`echo ${OLD_VERSION} | cut -s -d '-' -f 1 | cut -s -d '.' -f 1`
OLD_RUST_MINOR_VERSION=`echo ${OLD_VERSION} | cut -s -d '-' -f 1 | cut -s -d '.' -f 2`
OLD_OUR_MAJOR_VERSION=`echo ${OLD_VERSION} | cut -s -d '-' -f 2 | cut -s -d '.' -f 1`
OLD_OUR_MINOR_VERSION=`echo ${OLD_VERSION} | cut -s -d '-' -f 2 | cut -s -d '.' -f 2`

NEW_RUST_MAJOR_VERSION=`echo ${NEW_VERSION} | cut -s -d '-' -f 1 | cut -s -d '.' -f 1`
NEW_RUST_MINOR_VERSION=`echo ${NEW_VERSION} | cut -s -d '-' -f 1 | cut -s -d '.' -f 2`
NEW_OUR_MAJOR_VERSION=`echo ${NEW_VERSION} | cut -s -d '-' -f 2 | cut -s -d '.' -f 1`
NEW_OUR_MINOR_VERSION=`echo ${NEW_VERSION} | cut -s -d '-' -f 2 | cut -s -d '.' -f 2`

if [ "${NEW_RUST_MAJOR_VERSION}" -gt "${OLD_RUST_MAJOR_VERSION}" ]; then
    echo "Version increment OK: new Rust major version"
    exit 0
fi
if [ "${NEW_RUST_MAJOR_VERSION}" -lt "${OLD_RUST_MAJOR_VERSION}" ]; then
    echo "Version increment invalid: Rust major version went backwards" 1>&2
    exit 1
fi

if [ "${NEW_RUST_MINOR_VERSION}" -gt "${OLD_RUST_MINOR_VERSION}" ]; then
    echo "Version increment OK: new Rust minor version"
    exit 0
fi
if [ "${NEW_RUST_MINOR_VERSION}" -lt "${OLD_RUST_MINOR_VERSION}" ]; then
    echo "Version increment invalid: Rust minor version went backwards" 1>&2
    exit 1
fi

if [ "${NEW_OUR_MAJOR_VERSION}" -gt "${OLD_OUR_MAJOR_VERSION}" ]; then
    echo "Version increment OK: new internal major version"
    exit 0
fi
if [ "${NEW_OUR_MAJOR_VERSION}" -lt "${OLD_OUR_MAJOR_VERSION}" ]; then
    echo "Version increment invalid: internal major version went backwards" 1>&2
    exit 1
fi

if [ "${NEW_OUR_MINOR_VERSION}" -gt "${OLD_OUR_MINOR_VERSION}" ]; then
    echo "Version increment OK: new internal minor version"
    exit 0
fi
if [ "${NEW_OUR_MINOR_VERSION}" -lt "${OLD_OUR_MINOR_VERSION}" ]; then
    echo "Version increment invalid: internal minor version went backwards" 1>&2
    exit 1
fi

echo "Version increment invalid: nothing seems to have changed" 1>&2
exit 1