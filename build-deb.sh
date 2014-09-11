#!/bin/bash
FULL_PATH=`pwd`
PROJECT_NAME=avdm
BUILD_PATH=$FULL_PATH/tmp
VERSION="0.1"
ARCH="amd64"

make_package_files()
{
    mkdir -p $BUILD_PATH/usr/bin
    chmod 755 -R $BUILD_PATH
    echo -n "Moving files for package. Please wait ..."
    # Move main script
    go install github.com/gronpipmaster/$PROJECT_NAME
    mv $GOPATH/bin/$PROJECT_NAME $BUILD_PATH/usr/bin/$PROJECT_NAME

    echo "Done"
}

make_control_file()
{
    echo -n "Make Debian control file ..."
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
    fakeroot dpkg-deb -b $BUILD_PATH ${PROJECT_NAME}_${VERSION}_${ARCH}.deb
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