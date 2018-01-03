#!/bin/bash

ZIP_NAME='rds-copy-snapshots.py.zip'

# Create the build directory
#rm $ZIP_NAME
rm -rf build
mkdir build

# Copy the sources
cp rds-copy-snapshots.py build/

# Create zip directory
cd build
zip -r "../../../files/${ZIP_NAME}" *

# clean up
cd ..

rm -rf build