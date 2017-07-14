#!/bin/bash

fw_depends redis dlang

# Clean any files from last run
rm -f fwb
rm -rf .dub

dub build -c redis -b release --compiler=ldc2 --combined

./fwb &
