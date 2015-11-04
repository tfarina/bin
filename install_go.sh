#!/bin/bash

echo
echo "Installing Go..."
echo

GO_VERSION=go1.5.1.linux-amd64
wget https://storage.googleapis.com/golang/$GO_VERSION.tar.gz
sudo tar -C /usr/local -xzf $GO_VERSION.tar.gz
rm $GO_VERSION.tar.gz
