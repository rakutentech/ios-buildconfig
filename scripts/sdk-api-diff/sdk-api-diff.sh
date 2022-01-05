#!/bin/bash
set -e

usage="--------------------------------------------
Compares API differences between two module versions.
The script generates '<module name>.diff' file based on two modules at given paths.
The path must contain either .framework file (default) or Swift Module project (--spm option) 

Usage: sdk-api-diff <module name> <module v1 path> <module v2 path> [OPTIONS]

Options:
  --target: Target platform and version e.g. x86_64-apple-ios14.0-simulator or arm64-apple-ios14.0
    (Default: x86_64-apple-ios14.0-simulator)
  --sdkpath: Path to target's SDK.
    (Default: output of 'xcrun --sdk iphonesimulator --show-sdk-path')
  --spm: Use this option for Swift Module projects. Input paths must contain buildable SPM project.
  --help: Dispalys help content."

MODULE_NAME=$1
MODULE_A_DIR=$2
MODULE_B_DIR=$3

# default values
TARGET_NAME=x86_64-apple-ios14.0-simulator
SDK_DIR=`xcrun --sdk iphonesimulator --show-sdk-path`
SPM_MODE=false

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
    --spm)
      SPM_MODE=true
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

if [ -z ${MODULE_NAME} ] || [ -z ${MODULE_A_DIR} ] || [ -z ${MODULE_B_DIR} ]; then
    echo "Error: Missing required arguments"
    printf -- "$usage"
    exit 1
fi
if [ ! -d `eval echo $MODULE_A_DIR` ]; then
    echo "Invalid path: $MODULE_A_DIR"
    exit 1
fi
if [ ! -d `eval echo $MODULE_B_DIR` ]; then
    echo "Invalid path: $MODULE_B_DIR"
    exit 1
fi

echo "Checking swift tools..."
xcrun --toolchain swift -f swift-api-digester

if [ "$SPM_MODE" = false ] ; then

  REQUEST_TEMPLATE="sdk-api-diff-request-template.yml"
  if [ ! -f $REQUEST_TEMPLATE ]; then
      echo "Missing $REQUEST_TEMPLATE file"
      exit 1
  fi

  hash jq 2> /dev/null || { echo >&2 'ERROR: jq must be installed (`breq install jq`)'; exit 1; }
  hash sourcekitten 2> /dev/null || { echo >&2 'ERROR: sourcekitten must be installed (`breq install sourcekitten`)'; exit 1; }

  # Export vars for yaml template
  export TARGET_NAME
  export SDK_DIR
  export MODULE_NAME
  export MODULE_DIR=$MODULE_A_DIR
  export SOURCEKITTEN_REQUEST_NAME="request-A"

  # Replace the {{KEY}} in yaml file with the values from the environment variables
  cat $REQUEST_TEMPLATE | perl -pe 's/\{\{(\w+)\}\}/$ENV{$1}/eg' > requestA.yml

  export MODULE_DIR=$MODULE_B_DIR
  export SOURCEKITTEN_REQUEST_NAME="request-B"
  cat $REQUEST_TEMPLATE | perl -pe 's/\{\{(\w+)\}\}/$ENV{$1}/eg' > requestB.yml

  # Perform the sourcekitten request with the generated request yaml, extract the source 
  sourcekitten request --yaml requestA.yml | jq -r '.["key.sourcetext"]' > moduleA.swift
  sourcekitten request --yaml requestB.yml | jq -r '.["key.sourcetext"]' > moduleB.swift

  # Generate API diff
  set +e # diff exit code 1 means that differences were found.
  diff moduleA.swift moduleB.swift > $MODULE_NAME.diff
  set -e
  echo "API diff generated to $(pwd)/$MODULE_NAME.diff"

  # Print API diff summary
  xcrun --toolchain swift swift-api-digester --dump-sdk -module $MODULE_NAME -I $MODULE_A_DIR -F $MODULE_A_DIR -sdk $SDK_DIR -o moduleA.json -target $TARGET_NAME
  xcrun --toolchain swift swift-api-digester --dump-sdk -module $MODULE_NAME -I $MODULE_B_DIR -F $MODULE_B_DIR -sdk $SDK_DIR -o moduleB.json -target $TARGET_NAME
  echo "API Breakage Summary:"
  xcrun --toolchain swift swift-api-digester --diagnose-sdk --input-paths moduleA.json --input-paths moduleB.json

  # cleanup
  rm -f moduleA.swift moduleB.swift requestA.yml requestB.yml moduleA.json moduleB.json
else
  hash moduleinterface 2> /dev/null || { echo >&2 'ERROR: moduleinterface must be installed (https://github.com/minuscorp/ModuleInterface)'; exit 1; }
  working_dir=`pwd`

  cd $MODULE_A_DIR
  # Build Module A
  swift build -Xswiftc "-sdk" -Xswiftc $SDK_DIR -Xswiftc "-target" -Xswiftc $TARGET_NAME
  # Generate swift interface of Module A
  moduleinterface generate --spm-module $MODULE_NAME

  cd $MODULE_B_DIR
  # Build Module B
  swift build -Xswiftc "-sdk" -Xswiftc $SDK_DIR -Xswiftc "-target" -Xswiftc $TARGET_NAME
  # Generate swift interface of Module B
  moduleinterface generate --spm-module $MODULE_NAME
  cd $working_dir

  # Generate API diff
  set +e # diff exit code 1 means that differences were found.
  diff "$MODULE_A_DIR/Documentation/$MODULE_NAME.swift" "$MODULE_B_DIR/Documentation/$MODULE_NAME.swift"  > $MODULE_NAME.diff
  set -e

  # Print API diff summary
  xcrun --toolchain swift swift-api-digester --dump-sdk -module $MODULE_NAME -I "$MODULE_A_DIR/.build/debug/" -F "$MODULE_A_DIR/.build/debug/" -sdk $SDK_DIR -o moduleA.json -target $TARGET_NAME
  xcrun --toolchain swift swift-api-digester --dump-sdk -module $MODULE_NAME -I "$MODULE_B_DIR/.build/debug/" -F "$MODULE_B_DIR/.build/debug/" -sdk $SDK_DIR -o moduleB.json -target $TARGET_NAME
  echo "API Breakage Summary:"
  xcrun --toolchain swift swift-api-digester --diagnose-sdk --input-paths moduleA.json --input-paths moduleB.json

  # cleanup
  rm -f "$MODULE_A_DIR/Documentation/$MODULE_NAME.swift"
  rm -f "$MODULE_B_DIR/Documentation/$MODULE_NAME.swift"
  rm -f moduleA.json moduleB.json
fi
