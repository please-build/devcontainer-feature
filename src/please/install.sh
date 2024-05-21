#!/usr/bin/env bash

set -ex

PLEASE_VERSION=${VERSION}

# Start of functions copied and modified from https://github.com/devcontainers/features/blob/main/src/git/install.sh

#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    VERSION_CODENAME="${ID}{$VERSION_ID}"
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi

if type apt-get > /dev/null 2>&1; then
    INSTALL_CMD=apt-get
elif type microdnf > /dev/null 2>&1; then
    INSTALL_CMD=microdnf
elif type dnf > /dev/null 2>&1; then
    INSTALL_CMD=dnf
elif type yum > /dev/null 2>&1; then
    INSTALL_CMD=yum
else
    echo "(Error) Unable to find a supported package manager."
    exit 1
fi

# Clean up
clean_up() {
    case $ADJUSTED_ID in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        rhel)
            rm -rf /var/cache/dnf/*
            rm -rf /var/cache/yum/*
            ;;
    esac
}
clean_up

pkg_mgr_update() {
    if [ ${INSTALL_CMD} = "apt-get" ]; then
        if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
            echo "Running apt-get update..."
            ${INSTALL_CMD} update -y
        fi
    elif [ ${INSTALL_CMD} = "dnf" ] || [ ${INSTALL_CMD} = "yum" ]; then
        if [ "$(find /var/cache/${INSTALL_CMD}/* | wc -l)" = "0" ]; then
            echo "Running ${INSTALL_CMD} check-update ..."
            ${INSTALL_CMD} check-update
        fi
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if [ ${INSTALL_CMD} = "apt-get" ]; then
        if ! dpkg -s "$@" > /dev/null 2>&1; then
            pkg_mgr_update
            ${INSTALL_CMD} -y install --no-install-recommends "$@"
        fi
    elif [ ${INSTALL_CMD} = "dnf" ] || [ ${INSTALL_CMD} = "yum" ]; then
        _num_pkgs=$(echo "$@" | tr ' ' \\012 | wc -l)
        _num_installed=$(${INSTALL_CMD} -C list installed "$@" | sed '1,/^Installed/d' | wc -l)
        if [ ${_num_pkgs} != ${_num_installed} ]; then
            pkg_mgr_update
            ${INSTALL_CMD} -y install "$@"
        fi
    elif [ ${INSTALL_CMD} = "microdnf" ]; then
        ${INSTALL_CMD} -y install \
            --refresh \
            --best \
            --nodocs \
            --noplugins \
            --setopt=install_weak_deps=0 \
            "$@"
    else
        echo "Linux distro ${ID} not supported."
        exit 1
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Install required packages to build if missing
if [ "${ADJUSTED_ID}" = "debian" ]; then

    check_packages build-essential curl ca-certificates tar gettext libssl-dev zlib1g-dev libcurl?-openssl-dev libexpat1-dev

    check_packages libpcre2-dev

    if [ "${VERSION_CODENAME}" = "focal" ] || [ "${VERSION_CODENAME}" = "bullseye" ]; then
        check_packages libpcre2-posix2
    elif [ "${VERSION_CODENAME}" = "bionic" ] || [ "${VERSION_CODENAME}" = "buster" ]; then
        check_packages libpcre2-posix0
    else
        check_packages libpcre2-posix3
    fi

elif [ "${ADJUSTED_ID}" = "rhel" ]; then

    if [ $VERSION_CODENAME = "centos7" ]; then
        check_packages centos-release-scl
        check_packages devtoolset-11
        source /opt/rh/devtoolset-11/enable
    else
        check_packages gcc
    fi


    check_packages libcurl-devel expat-devel gettext-devel openssl-devel perl-devel zlib-devel cmake pcre2-devel tar gzip ca-certificates
    if ! type curl > /dev/null 2>&1; then
        check_packages curl
    fi
    if [ $ID = "mariner" ]; then
        check_packages glibc-devel kernel-headers binutils
    fi
fi

# Partial version matching
if [ "$(echo "${PLEASE_VERSION}" | grep -o '\.' | wc -l)" != "2" ]; then
    requested_version="${PLEASE_VERSION}"
    version_list="$(curl -sSL -H "Accept: application/vnd.github.v3_json" "https://api.github.com/repos/thought-machine/please/tags" | grep -oP '"name":\s*"v\K[0-9]+\.[0-9]+\.[0-9]+"' | tr -d '"' | sort -rV )"
    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "current" ]; then
        PLEASE_VERSION="$(echo "${version_list}" | head -n 1)"
    else
        set +e
        PLEASE_VERSION="$(echo "${version_list}" | grep -E -m 1 "^${requested_version//./\\.}([\\.\\s]|$)")"
        set -e
    fi
    if [ -z "${PLEASE_VERSION}" ] || ! echo "${version_list}" | grep "^${PLEASE_VERSION//./\\.}$" > /dev/null 2>&1; then
        echo "Invalid please version: ${requested_version}" >&2
        exit 1
    fi
fi

# End of functions copied and modified from https://github.com/devcontainers/features/blob/main/src/git/install.sh

# Duplicates some logic from https://github.com/thought-machine/please/blob/master/tools/misc/get_plz.sh

ARCH=`uname -m`
if [ "$ARCH" = "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" = "amd64" ]; then
    :
elif [ "$ARCH" = "arm64" ]; then
    :
elif [ "$ARCH" = "aarch64" ]; then
    ARCH="arm64"
else
    echo "Unsupported cpu arch $ARCH"
    exit 1
fi

echo "Downloading source for ${PLEASE_VERSION}..."
curl -sL https://get.please.build/linux_${ARCH}/${PLEASE_VERSION}/please_${PLEASE_VERSION}.tar.gz | tar -xzC /tmp 2>&1
echo "Building..."
cd /tmp/please
ln -snf please plz
install please plz /usr/local/bin
rm -rf /tmp/please
echo "Done!"
echo "Installing completions..."
echo "source <(plz --completion_script)" >> ${_CONTAINER_USER_HOME}/.bashrc
echo "source <(plz --completion_script)" >> ${_CONTAINER_USER_HOME}/.zshrc
echo "Done!"
