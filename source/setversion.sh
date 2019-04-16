#!/bin/bash

PROJECT=$1
VERSION=$2

TYPE=$(echo ${VERSION} | cut -d\: -f1)
VERSION=$(echo ${VERSION} | cut -d\: -f2)

echo "Setting ${PROJECT} to version ${TYPE} ${VERSION}"

case ${TYPE} in
  TAG)
  	cd /source/${PROJECT}; git fetch; git checkout tags/${VERSION}
    ;;
  HASH)
  	cd /source/${PROJECT}; git fetch; git checkout ${VERSION}
    ;;
  BRANCH)
  	cd /source/${PROJECT}; git fetch; git checkout ${VERSION}
    ;;
  *)
		echo Invalid VERSION type
		exit -1
    ;;
esac

