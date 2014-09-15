#!/bin/bash
readonly FULL_PATH=`pwd`
readonly PROJECT_NAME=avdm
readonly BUILD_PATH=$FULL_PATH/tmp
VERSION="0.0"
ARCH="amd64"

make_package_files()
{
    mkdir -p $BUILD_PATH/usr/bin
    chmod 755 -R $BUILD_PATH
    echo "Download dependens for package project. Please wait ..."
    go get -v -t -u github.com/gronpipmaster/$PROJECT_NAME
    cd $GOPATH/src/github.com/gronpipmaster/$PROJECT_NAME
    VERSION=$(git describe --abbrev=5 --tags)
    go build -o $BUILD_PATH/usr/bin/$PROJECT_NAME -ldflags "-X main.version $VERSION" github.com/gronpipmaster/$PROJECT_NAME || exit 1
    echo "Done"
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

    echo "Done"
}

make_package()
{
    fakeroot dpkg-deb -b $BUILD_PATH ${FULL_PATH}/${PROJECT_NAME}_${VERSION}_${ARCH}.deb || exit 1
}

clean()
{
    rm -r $BUILD_PATH
}

make_package_files
make_control_file
make_package
clean

echo "All Done."
exit 0