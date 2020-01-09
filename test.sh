#!/bin/bash

set -x

# Create ttmat
./create-ttmat -f ttmat.bin -d 3 -m 100,100,100 -n 100,100,100 -r 5,8

# Create ttvec
./create-ttvec -f ttvec.bin -d 3 -m 100,100,100 -r 4,2

# Compute
./ttmatvec -a ttmat.bin -x ttvec.bin -y vecy.bin

# Compare with baseline
./compare-ttvec -x vecy.bin -y vecy-ref.bin

