#!/bin/bash

echo
echo "Installing cppcheck..."

VERSION=1.69
CPPCHECK_VERSION=cppcheck-$VERSION
cd
wget http://downloads.sf.net/project/cppcheck/cppcheck/$VERSION/$CPPCHECK_VERSION.tar.gz
tar -zxvf $CPPCHECK_VERSION.tar.gz
cd $CPPCHECK_VERSION
sudo make install
cd ..
rm -rf $CPPCHECK_VERSION
rm $CPPCHECK_VERSION.tar.gz
