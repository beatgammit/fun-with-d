#!/bin/bash

# make sure dmd knows where ev.d is
# this assumes that deimos/ev.d is in the current dir
dmd $1.d ./deimos/ev.d -L-lev -version=LIBEV4
rm $1.o
