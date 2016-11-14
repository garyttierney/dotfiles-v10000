#!/usr/bin/sh

BUILD_PATH="$HOME/.dotfiles_build"
CURRENT_PATH=$(pwd)
DESTINATION_PATH=""

while getopts ":d:b:" opt; do
	case $opt in
		d)
			DESTINATION_PATH="$OPTARG"
			;;
		b)
			BUILD_PATH="$OPTARG"
			;;
		?)
			echo "Unknown option -$OPTARG" >&2
			exit 1
			;;
	esac
done

if [ -z "$DESTINATION_PATH" ]; then
	echo "Error: no destination directory given" >&2
	exit 1
fi

if [ ! -d "$DESTINATION_PATH" ]; then
	echo "Error: destination directory \"$DESTINATION_PATH\" does not exist" >&2
	exit 1
fi

if [ ! -w "$DESTINATION_PATH" ]; then
	echo "Error: destination directory is not writable by $USER" >&2
	exit 1
fi

if [ ! -d "$BUILD_PATH" ]; then
	mkdir -p "$BUILD_PATH"
fi

FINDCMD="find %PATH% -type f -not -name install.sh -not -path */.git/*"

for FILE in $(${FINDCMD/"%PATH%"/$CURRENT_PATH}); do
	FILE_BUILD=${FILE/$CURRENT_PATH/$BUILD_PATH}
	FILE_BUILD_DIR=${FILE_BUILD%/*}

	if [ ! -d "$FILE_BUILD_DIR" ]; then
		mkdir -p "$FILE_BUILD_DIR"
	fi

	cp "$FILE" "$FILE_BUILD"

	perl -p -i -e 's/%([^\%:]+):([^\%]+)%/`$1 $2 | tr -d "\n"`/ge' "$FILE_BUILD"
done

CONFLICTS=()

for FILE in $(${FINDCMD/"%PATH%"/"$BUILD_PATH"}); do
	FILE_DEST=${FILE/$BUILD_PATH/$DESTINATION_PATH}
	FILE_DEST_DIR=${FILE_DEST%/*}

	if [ "$FILE_DEST" -ef "$FILE" ]; then
		continue
	fi

	if [ -f "$FILE_DEST" ]; then
		CONFLICTS+=("$FILE_DEST")
		continue
	fi

	if [ ! -d "$FILE_DEST_DIR" ]; then
		mkdir -p "$FILE_DEST_DIR"
	fi

	ln -s "$FILE" "$FILE_DEST"
done

echo "Found ${#CONFLICTS[*]} conflicts"
for CONFLICT in ${CONFLICTS[*]}; do
	echo -e "\t$CONFLICT"
done
