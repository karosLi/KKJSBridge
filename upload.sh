#!/bin/sh

################# Get Parameters ############################
checkInMessage=""

function usage()
{
  echo "Simply upload component to a repo"
  echo ""
  echo "Options for upload:"
  echo "-m, --message STRING REQUIRED The check in message."
}

# $OPTARG to get arg value
# $OPTIND to get index
while getopts "m:" option
do
    case "$option" in
        m)
            checkInMessage=$OPTARG
            ;;

        message)
            checkInMessage=$OPTARG
            ;;

        \?)
            usage
            exit 1;;
    esac
done

shift "$((OPTIND-1))" # Shift off the options and optional --. For safety.

################# End Get Parameters ############################

if [[ ${checkInMessage} = "" ]]; then
		usage
		exit
	fi

./uploadRepo.sh -f KKJSBridge.podspec -m ${checkInMessage}
