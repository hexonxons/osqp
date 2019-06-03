#!/bin/bash
set -ev

OSQP_VERSION="0.6.0.dev2"
OSQP_PACKAGE_NAME="OSQP"
if [[ ${OSQP_VERSION} == *"dev"* ]]; then
    OSQP_PACKAGE_NAME="${OSQP_PACKAGE_NAME}-dev"
fi

# Update variables from install
# CMake
if [[ "${TRAVIS_OS_NAME}" == "linux" ]]; then
    export PATH=${DEPS_DIR}/cmake/bin:${PATH}
fi
# Anaconda
export PATH=${DEPS_DIR}/miniconda/bin:$PATH
hash -r
source activate testenv


echo "Creating Bintray package..."

# Compile OSQP
cd ${TRAVIS_BUILD_DIR}
rm -rf build
mkdir build
cd build
cmake -G "Unix Makefiles" ..
make

cd ${TRAVIS_BUILD_DIR}/build/out
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
    OS_NAME="mac"
    OS_SHARED_LIB_EXT="dylib"
else
    OS_NAME="linux"
    OS_SHARED_LIB_EXT="so"
fi
OSQP_BIN=osqp-${OSQP_VERSION}-${OS_NAME}64
mkdir $OSQP_BIN/
mkdir $OSQP_BIN/lib
mkdir $OSQP_BIN/include
# Copy license
cp ../../LICENSE $OSQP_BIN/
# Copy includes
cp ../../include/*.h  $OSQP_BIN/include
# Copy static library
cp libosqp.a $OSQP_BIN/lib
# Copy shared library
cp libosqp.$OS_SHARED_LIB_EXT $OSQP_BIN/lib
# Compress package
tar -czvf ${TRAVIS_BUILD_DIR}/$OSQP_BIN.tar.gz  $OSQP_BIN


echo "Creating Bintray sources package..."

OSQP_SOURCES=osqp-${OSQP_VERSION}
# Clone OSQP repository
cd ${TRAVIS_BUILD_DIR}
mkdir sources/
cd sources/
git clone https://github.com/$TRAVIS_REPO_SLUG.git ${OSQP_SOURCES} --recursive
cd ${OSQP_SOURCES}
git checkout -qf $TRAVIS_COMMIT
git submodule update
cd ..
# Create archive ignoring hidden files
tar --exclude=".*" -czvf ${TRAVIS_BUILD_DIR}/${OSQP_SOURCES}.tar.gz ${OSQP_SOURCES}

# Deploy package
curl -T ${TRAVIS_BUILD_DIR}/${OSQP_BIN}.tar.gz -ubstellato:$BINTRAY_API_KEY -H "X-Bintray-Package:${OSQP_PACKAGE_NAME}" -H "X-Bintray-Version:${OSQP_VERSION}" -H "X-Bintray-Override: 1" https://api.bintray.com/content/bstellato/generic/${OSQP_PACKAGE_NAME}/${OSQP_VERSION}/


# Deploy sources
curl -T ${TRAVIS_BUILD_DIR}/${OSQP_SOURCES}.tar.gz -ubstellato:$BINTRAY_API_KEY -H "X-Bintray-Package:${OSQP_PACKAGE_NAME}" -H "X-Bintray-Version:${OSQP_VERSION}" -H "X-Bintray-Override: 1" https://api.bintray.com/content/bstellato/generic/${OSQP_PACKAGE_NAME}/${OSQP_VERSION}/


# Publish deployed files
curl -X POST -ubstellato:$BINTRAY_API_KEY https://api.bintray.com/content/bstellato/generic/${OSQP_PACKAGE_NAME}/${OSQP_VERSION}/publish


exit 0
