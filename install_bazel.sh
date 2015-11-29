#!/bin/bash

echo "Installing Bazel..."
echo

wget https://storage.googleapis.com/bazel/0.1.2/rc2/bazel-0.1.2rc2-installer-linux-x86_64.sh
wget https://storage.googleapis.com/bazel/0.1.2/rc2/bazel-0.1.2rc2-installer-linux-x86_64.sh.sha256
sha256sum -c bazel-0.1.2rc2-installer-linux-x86_64.sh.sha256
chmod +x bazel-0.1.2rc2-installer-linux-x86_64.sh
./bazel-0.1.2rc2-installer-linux-x86_64.sh --user
