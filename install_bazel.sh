#!/bin/bash

echo "Installing Bazel..."
echo

VERSION=0.1.0
wget https://github.com/bazelbuild/bazel/releases/download/${VERSION}/bazel-${VERSION}-installer-linux-x86_64.sh
wget https://github.com/bazelbuild/bazel/releases/download/${VERSION}/bazel-${VERSION}-installer-linux-x86_64.sh.sha256
sha256sum -c bazel-${VERSION}-installer-linux-x86_64.sh.sha256
chmod +x bazel-${VERSION}-installer-linux-x86_64.sh
./bazel-${VERSION}-installer-linux-x86_64.sh --user
