#!/bin/bash
# NAME
#	create-stripped-image - strips the bare essentials from an image and exports them
#
# SYNOPSIS
#	create-stripped-image -i image-name -t target-image-name -t [-p package | -f file] [-v] 
#			
#
# OPTIONS
#	-i image-name		to strip
#	-t target-image-name	the image name of the stripped image
#	-p package		package to include from image, multiple -p allowed.
#	-f file			file to include from image, multiple -f allowed.
#	-v			verbose
#
# DESCRIPTION
#   	creates a new Docker image based on the scratch  which contains
#	only the the source image of selected packages and files.
#
# EXAMPLE
#	The following example strips the nginx installation from the default NGiNX docker image,
#
#        create-stripped-image -i nginx -t stripped-nginx  \
#			-p nginx  \
#			-f /etc/passwd \
#			-f /etc/group \
#			-f '/lib/*/libnss*' \
#			-f /bin/ls \
#			-f /bin/cat \
#			-f /bin/sh \
#			-f /bin/mkdir \
#			-f /bin/ps \
#			-f /var/run \
#			-f /var/log/nginx 
#

function usage() {
	echo "usage: $(basename $0) -i image-name -t stripped-image-name [-p package | -f file] [-v]" >&2
	echo "	$@" >&2
}

function parse_commandline() {

	while getopts "vi:t:p:f:" OPT; do
	    case "$OPT" in
		v)
		    VERBOSE=-v
		    ;;
		p)
		    PACKAGES="$PACKAGES -p $OPTARG"
		    ;;
		f)
		    FILES="$FILES -f $OPTARG"
		    ;;
		i)
		    IMAGE_NAME="$OPTARG"
		    ;;
		t)
		    TARGET_IMAGE_NAME="$OPTARG"
		    ;;
		*)
		    usage
		    exit 1
		    ;;
	    esac
	done
	shift $((OPTIND-1))

	if [ -z "$IMAGE_NAME" ] ; then
		usage "image name is missing."
		exit 1
	fi

	if [ -z "$TARGET_IMAGE_NAME" ] ; then
		usage "target image name -t missing."
		exit 1
	fi

	if [ -z "$PACKAGES" -a -z "$FILES" ] ; then
		usage "Missing -p or -f options"
		exit 1
	fi
	export PACKAGES FILES VERBOSE
}

parse_commandline "$@"

DIR=create-stripped-image-$$
mkdir -p $DIR/export
SCRIPT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

mkdir -p $DIR/fs
docker run -v $PWD/$DIR/fs:/export \
	  -v $SCRIPT_DIR:/mybin $IMAGE_NAME \
	  /mybin/create-stripped-image-export.sh -d /export $VERBOSE $PACKAGES $FILES

cat > $DIR/Dockerfile <<!
FROM scratch
ADD export /
!

(
	cd $DIR
	docker build --no-cache -t $TARGET_IMAGE_NAME .
)

rm -rf $DIR
