#!/usr/bin/env bash

cat << EOF > "$(git rev-parse --show-toplevel)/Dockerfile"
FROM ${DOCKER_BASE_IMAGE}
RUN make ${MAKEFLAGS}
RUN find cpp/src -name build -exec rm -rf {} + \\
    && find cpp/test -name pie -exec rm -rf {} +
EOF
