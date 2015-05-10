#!/bin/bash

echo
echo "Installing cppcheck..."

VERSION=1.69
CPPCHECK_VERSION=cppcheck-$VERSION
cd
wget http://downloads.sf.net/project/cppcheck/cppcheck/$VERSION/$CPPCHECK_VERSION.tar.gz
cd $CPPCHECK_VERSION
g++ -o cppcheck -std=c++0x -include lib/cxx11emu.h -Iexternals/tinyxml -Ilib cli/*.cpp lib/*.cpp externals/tinyxml/*.cpp
sudo install -D --verbose --backup=none --mode=755 -T cppcheck /usr/local/bin/cppcheck
cd ..
rm -rf $CPPCHECK_VERSION
rm $CPPCHECK_VERSION.tar.gz
