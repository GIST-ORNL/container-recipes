#!/bin/bash

set -e

# This script lives one directory below the top level container-recipes directory
TOP_DIR=$(cd `dirname $0`/.. && pwd)

# System directories in which to look for builds in
SYSTEMS=(titan summit)

# Loop through directory structure container-recipes/{SYSTEM}/{DISTRO}_{TAG} and build image
for SYSTEM in "${SYSTEMS[@]}" ; do
    SYSTEM_DIR=${TOP_DIR}/${SYSTEM}
    for DISTRO_DIR in ${SYSTEM_DIR}/*/ ; do
        DISTRO=$(basename ${DISTRO_DIR})
        if [[ ! -d ${DISTRO_DIR} ]]; then
            continue
        fi
        for VERSION_DIR in ${DISTRO_DIR}/*/ ; do
            if [[ ! -d ${VERSION_DIR} ]]; then
                continue
            fi
            cd ${VERSION_DIR}

            # Only build if the file ./.ci_build exists in the directory
            if [ ! -e ./.ci_build ]; then
                continue
            fi

            VERSION=$(basename ${VERSION_DIR})
            TAG="${DISTRO}_${VERSION}"
            GIT_NAME="code.ornl.gov:4567/olcf/container-recipes/${SYSTEM}"
            DOCKER_NAME="olcf/${SYSTEM}"

            # Copy QEMU binary to build directory if we're building for a power system
            if [ "${SYSTEM}" == "summitdev" ] || [ "${SYSTEM}" == "summit" ]; then
                cp ../../qemu-ppc64le-static .
            fi

            # Tag for both gitlab and Dockerhub
            docker build --label OLCF -t ${GIT_NAME}:${TAG} -t ${DOCKER_NAME}:${TAG} .
        done
    done
done

# Clean up images that aren't needed.
docker system prune -f
