#!/bin/bash
set -e

MOUNT_DIR="./original-iso"
BUILD_DIR="./custom-iso"
BUILD_PACKAGE_DIR="${BUILD_DIR}/dists/trusty/extras/binary-amd64"
BUILD_POOL_DIR="${BUILD_DIR}/pool/extras"
EXTRAS_DEB_DIR="/var/cache/apt/archives"

# Create a few directories.
if [ ! -d $MOUNT_DIR ]; then mkdir -p $MOUNT_DIR; fi

if [ -d $BUILD_DIR ]; then
    rm -rf $BUILD_DIR
fi
mkdir -p $BUILD_DIR

sudo mount -o loop ./ubuntu-14.04.2-server-amd64.iso $MOUNT_DIR
cp -r ${MOUNT_DIR}/* ${BUILD_DIR}/
cp -r ${MOUNT_DIR}/.disk/ ${BUILD_DIR}/
sudo umount $MOUNT_DIR


if [ ! -d $BUILD_PACKAGE_DIR ]; then mkdir -p $BUILD_PACKAGE_DIR; fi
if [ ! -d $BUILD_POOL_DIR ]; then mkdir -p $BUILD_POOL_DIR; fi

apt-ftparchive -v
if [[ $? != 0 ]]; then
    sudo apt-get install apt-ftparchive
else
    echo "apt-ftparchive is already installed!"
fi

cp ${EXTRAS_DEB_DIR}/*.deb ${BUILD_POOL_DIR}/

apt-ftparchive packages ${BUILD_POOL_DIR}/ > ${BUILD_PACKAGE_DIR}/Packages
gzip -c ${BUILD_PACKAGE_DIR}/Packages | tee ${BUILD_PACKAGE_DIR}/Packages.gz > /dev/null

#pushd ${BUILD_DIR} 
cd ${BUILD_DIR}

chmod +w ./md5sum.txt
find . -type f -print0 | xargs -0 md5sum | grep -v "\./md5sum.txt" | tee ./md5sum.txt

chmod +wx isolinux/isolinux.bin
sudo mkisofs -r -V "OPNFV" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-14.04-amd64-opnfv.iso .

cd ../
echo "finish makeiso"
#popd

