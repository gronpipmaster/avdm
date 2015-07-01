#!/bin/bash
readonly FULL_PATH=`pwd`
readonly PROJECT_NAME=avdm
readonly PROJECT_PATH=github.com/gronpipmaster/$PROJECT_NAME
readonly BUILD_PATH=$FULL_PATH/tmp
VERSION="0.0"
ARCH="amd64"

make_package_files()
{
    mkdir -p $BUILD_PATH/usr/bin
    chmod 0755 -R $BUILD_PATH
    echo "Download dependens for package project. Please wait ..."
    go get -v -t $PROJECT_PATH
    cd $GOPATH/src/$PROJECT_PATH
    VERSION=$(git describe --abbrev=5 --tags)
    go build -o $BUILD_PATH/usr/bin/$PROJECT_NAME -ldflags "-X main.version $VERSION" $PROJECT_PATH || exit 1
    echo "Done."
}

make_control_file()
{
    echo "Make Debian control file ..."
    mkdir -p $BUILD_PATH/DEBIAN
    #calculate installed size
    full_size=`du -s $BUILD_PATH/usr | awk '{print $1}'`

    filename=$BUILD_PATH/DEBIAN/control
    echo "Package: $PROJECT_NAME" > $filename
    echo "Version: $VERSION" >> $filename
    echo "Architecture: $ARCH" >> $filename
    echo "Section: devel" >> $filename
    echo "Priority: extra" >> $filename
    echo "Installed-Size: $full_size" >> $filename
    echo "Maintainer: gronpipmaster <gronpipmaster@localhost.r>" >> $filename
    echo "Description: System info, avg free space and memory." >> $filename

    echo "Done."
}

make_package()
{
    #reset rigth for rpm
    chmod 0555 $BUILD_PATH/usr/bin
    chmod 0555 $BUILD_PATH
    local DEB_NAME=${PROJECT_NAME}_${VERSION}_${ARCH}
    echo "Make $DEB_NAME.deb"
    fakeroot dpkg-deb -b $BUILD_PATH ${FULL_PATH}/${DEB_NAME}.deb || exit 1
    echo "Make $DEB_NAME.rpm"
    fakeroot alien --to-rpm --scripts ${FULL_PATH}/${DEB_NAME}.deb || exit 1
}

clean()
{
    chmod -R 0775 $BUILD_PATH
    rm -r $BUILD_PATH
}

make_package_files
make_control_file
make_package
clean

echo "All Done."
exit 0