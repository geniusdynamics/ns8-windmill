#!/bin/bash

#
# Copyright (C) 2023 Nethesis S.r.l.
# SPDX-License-Identifier: GPL-3.0-or-later
#

# Terminate on error
set -e

# Prepare variables for later use
images=()
# The image will be pushed to GitHub container registry
repobase="${REPOBASE:-ghcr.io/geniusdynamics}"
# Configure the image name
reponame="windmill"
# Node.js 25+ no longer ships Corepack, install it from npm
# renovate: datasource=npm packageName=corepack
corepack_version=0.36.0

# Create a new empty container image
container=$(buildah from scratch)

# Reuse existing nodebuilder-windmill container, to speed up builds
if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-windmill; then
	echo "Pulling NodeJS runtime..."
	buildah from --name nodebuilder-windmill -v "${PWD}:/usr/src:Z" docker.io/library/node:26.13.0-slim
	buildah run nodebuilder-windmill sh -c "npm install -g corepack@${corepack_version} && corepack enable"
fi

echo "Build static UI files with node..."
buildah run \
	--workingdir=/usr/src/ui \
	--env="NODE_OPTIONS=--openssl-legacy-provider" \
	nodebuilder-windmill \
	sh -c "yarn install && yarn build"

# Add imageroot directory to the container image
buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Setup the entrypoint, ask to reserve one TCP port with the label and set a rootless container
# The Windmill images (server, workers, extra services) are pinned to the
# same release. windmill-extra bundles the language server, the debugger and
# the (Enterprise Edition) multiplayer service.
# rootfull=0 === rootless container
# tcp-ports-demand=1 number of tcp Port to reserve , 1 is the minimum, can be udp or tcp
buildah config --entrypoint=/ \
	--label="org.nethserver.authorizations=traefik@node:routeadm" \
	--label="org.nethserver.tcp-ports-demand=1" \
	--label="org.nethserver.rootfull=0" \
	--label="org.nethserver.min-core=3.12.4-0" \
	--label="org.nethserver.images=ghcr.io/windmill-labs/windmill:1.871.1 ghcr.io/windmill-labs/windmill-extra:1.871.1 ghcr.io/windmill-labs/caddy-l4:2.11.4-1 docker.io/postgres:18.7" \
	"${container}"
# Commit the image
buildah commit "${container}" "${repobase}/${reponame}"

# Append the image URL to the images array
images+=("${repobase}/${reponame}")

#
# NOTICE:
#
# It is possible to build and publish multiple images.
#
# 1. create another buildah container
# 2. add things to it and commit it
# 3. append the image url to the images array
#

#
# Setup CI when pushing to Github.
# Warning! docker::// protocol expects lowercase letters (,,)
if [[ -n "${CI}" ]]; then
	# Set output value for Github Actions
	printf "images=%s\n" "${images[*],,}" >>"${GITHUB_OUTPUT}"
else
	# Just print info for manual push
	printf "Publish the images with:\n\n"
	for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}"; done
	printf "\n"
fi
