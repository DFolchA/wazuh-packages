#!/bin/bash

# Wazuh package generator
# Copyright (C) 2015-2019, Wazuh Inc.
#
# This program is a free software; you can redistribute it
# and/or modify it under the terms of the GNU General Public
# License (version 2) as published by the FSF - Free Software
# Foundation.

CURRENT_PATH="$( cd $(dirname $0) ; pwd -P )"
ARCHITECTURE="amd64"
OUTDIR="${HOME}/3.x/apt-dev/"
BRANCH="master"
REVISION="1"
TARGET=""
JOBS="2"
DEBUG="no"
INSTALLATION_PATH="/var/ossec"
DEB_AMD64_BUILDER="deb_builder_amd64"
DEB_I386_BUILDER="deb_builder_i386"
DEB_AMD64_BUILDER_DOCKERFILE="${CURRENT_PATH}/Debian/amd64"
DEB_I386_BUILDER_DOCKERFILE="${CURRENT_PATH}/Debian/i386"

if [ -z "$OUTDIR" ]
then
    if [ -n "$DEB_OUTDIR" ]
    then
        OUTDIR=$DEB_OUTDIR
    else
        echo "ERROR: \$DEB_OUTDIR was not defined."
        echo "Tip: echo export DEB_OUTDIR=\"/my/output/dir\" >> ~/.bash_profile"
        return 1
    fi
fi

build_deb() {
    CONTAINER_NAME="$1"
    DOCKERFILE_PATH="$2"

    SOURCES_DIRECTORY="/tmp/wazuh-builder/sources-$(( ( RANDOM % 1000 )  + 1 ))"

    # Download the sources
    git clone ${SOURCE_REPOSITORY} -b $BRANCH ${SOURCES_DIRECTORY} --depth=1 --single-branch -q
    # Copy the necessary files
    cp build.sh ${DOCKERFILE_PATH}
    cp gen_permissions.sh ${SOURCES_DIRECTORY}

    if [[ "$TARGET" != "api" ]]; then
        VERSION="$(cat ${SOURCES_DIRECTORY}/src/VERSION | cut -d 'v' -f 2)"
    else
        VERSION="$(grep version ${SOURCES_DIRECTORY}/package.json | cut -d '"' -f 4)"
    fi

    # Copy the "specs" files for the Debian package
    cp -rp SPECS/$VERSION/wazuh-$TARGET ${DOCKERFILE_PATH}/

    # Build the Docker image
    docker build -t ${CONTAINER_NAME} ${DOCKERFILE_PATH}

    # Build the Debian package with a Docker container
    docker run -t --rm -v $OUTDIR:/var/local/wazuh \
        -v ${SOURCES_DIRECTORY}:/build_wazuh/$TARGET/wazuh-$TARGET-$VERSION \
        -v ${DOCKERFILE_PATH}/wazuh-$TARGET:/$TARGET \
        ${CONTAINER_NAME} $TARGET $VERSION $ARCHITECTURE \
        $REVISION $JOBS $INSTALLATION_PATH $DEBUG $CHECKSUM || exit 1

    # Clean the files
    rm -rf ${DOCKERFILE_PATH}/{*.sh,*.tar.gz,wazuh-*} ${SOURCES_DIRECTORY}

    echo "Package $(ls $OUTDIR -Art | tail -n 1) added to $OUTDIR."

    return 0
}

build() {

    if [[ "$TARGET" = "api" ]]; then

        SOURCE_REPOSITORY="https://github.com/wazuh/wazuh-api"
        build_deb ${DEB_AMD64_BUILDER} ${DEB_AMD64_BUILDER_DOCKERFILE} || exit 1

    elif [[ "$TARGET" = "manager" ]] || [[ "$TARGET" = "agent" ]]; then

        SOURCE_REPOSITORY="https://github.com/wazuh/wazuh"
        BUILD_NAME=""
        FILE_PATH=""
        if [[ "$ARCHITECTURE" = "x86_64" ]] || [[ "$ARCHITECTURE" = "amd64" ]]; then
            ARCHITECTURE="amd64"
            BUILD_NAME="${DEB_AMD64_BUILDER}"
            FILE_PATH="${DEB_AMD64_BUILDER_DOCKERFILE}"
        elif [[ "$ARCHITECTURE" = "i386" ]]; then
            BUILD_NAME="${DEB_I386_BUILDER}"
            FILE_PATH="${DEB_I386_BUILDER_DOCKERFILE}"
        else
            echo "Invalid architecture. Choose: x86_64 (amd64 is accepted too) or i386."
            exit 1
        fi
        build_deb ${BUILD_NAME} ${FILE_PATH}|| exit 1
    else
        echo "Invalid target. Choose: manager, agent or api."
        exit 1
    fi

    return 0
}

help() {
    echo
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "    -b, --branch <branch>     [Required] Select Git branch [$BRANCH]. By default: master."
    echo "    -t, --target              [Required] Target package to build: manager, api or agent."
    echo "    -a, --architecture        [Optional] Target architecture of the package. By default: x86_64"
    echo "    -j, --jobs                [Optional] Change number of parallel jobs when compiling the manager or agent. By default: 4."
    echo "    -r, --release             [Optional] Package release. By default: 1."
    echo "    -p, --path                [Optional] Installation path for the package. By default: /var/ossec."
    echo "    -d, --debug               [Optional] Build the binaries with debug symbols. By default: no."
    echo "    -k, --checksum            [Optional] Generate checksum"
    echo "    -h, --help                Show this help."
    echo
    exit $1
}


main() {
    BUILD="no"
    CHECKSUM="yes"
    while [ -n "$1" ]
    do
        case "$1" in
        "-b"|"--branch")
            if [ -n "$2" ]
            then
                BRANCH="$(echo $2 | cut -d'/' -f2)"
                BUILD="yes"
                shift 2
            else
                help 1
            fi
            ;;
        "-h"|"--help")
            help 0
            ;;
        "-t"|"--target")
            if [ -n "$2" ]
            then
                TARGET="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-a"|"--architecture")
            if [ -n "$2" ]
            then
                ARCHITECTURE="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-j"|"--jobs")
            if [ -n "$2" ]
            then
                JOBS="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-r"|"--revision")
            if [ -n "$2" ]
            then
                REVISION="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-p"|"--path")
            if [ -n "$2" ]
            then
                INSTALLATION_PATH="$2"
                shift 2
            else
                help 1
            fi
            ;;
        "-d"|"--debug")
            DEBUG="yes"
            shift 1
            ;;
        "-k"|"--checksum")
            CHECKSUM="yes"
            shift 1
            ;;
        *)
            help 1
        esac
    done

    if [[ "$BUILD" != "no" ]]; then
        build || exit 1
    fi


    return 0
}

main "$@"
