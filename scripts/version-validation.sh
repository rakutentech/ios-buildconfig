#!/usr/bin/env bash

set -e

if [[ -n $1 ]];
then
    if [[ $1 =~ ^(0|[1-9][[:digit:]]*)\.(0|[1-9][[:digit:]]*)\.(0|[1-9][[:digit:]]*)$ ]];
    then
        echo "version input is valid.";
    else
        echo "version input is invalid.";
        exit 1;
    fi
else
    echo "version input (format: x.y.z) is missing.";
    exit 1;
fi
