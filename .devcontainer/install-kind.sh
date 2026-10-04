#!/usr/bin/env bash
# Codespaces を作ったときに kind を入れる（版を固定）
set -euo pipefail
KIND_VERSION=v0.33.0
ARCH=$(dpkg --print-architecture)   # amd64 または arm64
curl -fsSLo /tmp/kind "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}"
curl -fsSLo /tmp/kind.sha256 "https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-${ARCH}.sha256sum"
echo "$(cut -d' ' -f1 /tmp/kind.sha256)  /tmp/kind" | sha256sum -c -
sudo install -m 0755 /tmp/kind /usr/local/bin/kind
kind version
