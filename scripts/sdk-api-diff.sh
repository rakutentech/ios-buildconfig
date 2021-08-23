#!/bin/bash
set -e

usage="--------------------------------------------
Description: Compares API differences between two module versions.

Usage: sdk-api-diff <module name> <module A path> <module B path> [OPTIONS]

Options:
  --target: Target platform and version e.g. x86_64-apple-ios14.0-simulator or arm64-apple-ios14.0
    (Default: x86_64-apple-ios14.0-simulator)
  --sdkpath: Path to target's SDK.
    (Default: output of 'xcrun --sdk iphonesimulator --show-sdk-path')"

# default values
TARGET_NAME=x86_64-apple-ios14.0-simulator
SDK_DIR=`xcrun --sdk iphonesimulator --show-sdk-path`

for i in "$@"; do
  case $i in
    --target=*)
      TARGET_NAME="${i#*=}"
      shift
      ;;
    --sdkpath=*)
      SDK_DIR="${i#*=}"
      shift
      ;;
    --help)
      printf -- "$usage"
      exit 0
      ;;
    *)
      # unknown option
      ;;
  esac
done

if [ -z ${1+x} ] || [ -z ${2+x} ] || [ -z ${3+x} ]; then
    echo "Error: Missing required arguments"
    printf -- "$usage"
    exit 1
fi
if [ ! -d $2 ]; then
    echo "Invalid path: $2"
    exit 1
fi
if [ ! -d $3 ]; then
    echo "Invalid path: $3"
    exit 1
fi
REQUEST_TEMPALTE="sdk-api-diff-request-tempalte.yml"
if [ ! -f $REQUEST_TEMPALTE ]; then
    echo "Missing $REQUEST_TEMPALTE file"
    exit 1
fi

hash jq 2> /dev/null || { echo >&2 "ERROR: jq must be installed"; exit 1; }
hash sourcekitten 2> /dev/null || { echo >&2 "ERROR: sourcekitten must be installed"; exit 1; }

MODULE_NAME=$1
MODULE_A_DIR=$2
MODULE_B_DIR=$3

# Export vars for yaml template
export TARGET_NAME
export SDK_DIR
export MODULE_NAME
export MODULE_DIR=$MODULE_A_DIR

# Replace the {{KEY}} in yaml file with the values from the environment variables
cat $REQUEST_TEMPALTE | perl -pe 's/\{\{(\w+)\}\}/$ENV{$1}/eg' > requestA.yml

export MODULE_DIR=$MODULE_B_DIR
cat $REQUEST_TEMPALTE | perl -pe 's/\{\{(\w+)\}\}/$ENV{$1}/eg' > requestB.yml

# Perform the sourcekitten request with the generated request yaml, extract the source 
sourcekitten request --yaml requestA.yml | jq -r '.["key.sourcetext"]' > moduleA.swift
sourcekitten request --yaml requestB.yml | jq -r '.["key.sourcetext"]' > moduleB.swift

# Print API diff
set +e # diff exit code 1 means that differences were found.
diff moduleA.swift moduleB.swift
set -e

# Print API diff summary
xcrun swift-api-digester --dump-sdk -module $MODULE_NAME -I $MODULE_A_DIR -F $MODULE_A_DIR -sdk $SDK_DIR -o moduleA.json -target $TARGET_NAME
xcrun swift-api-digester --dump-sdk -module $MODULE_NAME -I $MODULE_B_DIR -F $MODULE_B_DIR -sdk $SDK_DIR -o moduleB.json -target $TARGET_NAME
xcrun swift-api-digester --diagnose-sdk --input-paths moduleA.json --input-paths moduleB.json

# cleanup
rm -f moduleA.swift moduleB.swift requestA.yml requestB.yml moduleA.json moduleB.json

