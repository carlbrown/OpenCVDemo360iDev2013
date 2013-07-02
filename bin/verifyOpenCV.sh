#!/bin/sh

set -x

FRAMEWORK_URL="http://sourceforge.net/projects/opencvlibrary/files/opencv-ios/2.4.6/opencv2.framework.zip/download"
FRAMEWORKZIPFILE="opencv2.framework.zip"
FRAMEWORKHEADERFILE="opencv2.framework/Headers/opencv.hpp"

cd ${SOURCE_ROOT}/../External/
if [ -f "${FRAMEWORKHEADERFILE}" ] ; then
	exit 0
else
	echo "Downloading OpenCV framework from ${FRAMEWORK_URL}"
	curl -LJOsS ${FRAMEWORK_URL}
	if [ ! -f ${FRAMEWORKZIPFILE} ] ; then
		echo "FAILED TO DOWNLOAD ${FRAMEWORKZIPFILE}" >&2
		exit 2
	fi
	unzip ${FRAMEWORKZIPFILE}
	if [ ! -f "${FRAMEWORKHEADERFILE}"] ; then
		echo "FAILED TO UNPACK ${${FRAMEWORKHEADERFILE}} from ${FRAMEWORKZIPFILE}" >&2
		exit 2
	fi
	exit 0
fi