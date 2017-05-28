#!/bin/sh

rm -f test/Lulifile
export LULI=$1; nosetests test
