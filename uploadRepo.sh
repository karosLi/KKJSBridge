#!/bin/sh

################# Constant ############################
# Release 版本升级的类型
# -a 是release 大版本
# -b 是中版本
# -c 是小版本
a_build_version='a'
b_build_version='b'
c_build_version='c'

################# End Constant ########################

################# Get Parameters ############################
#pod spec file
podspecFile=""
build_version_type=$c_build_version
checkInMessage=""

function usage()
{
  echo "Upload component to private repo"
  echo ""
  echo "Options for upload:"
  echo "-f, --file STRING REQUIRED The podspec file." 
  echo "-v, --versiontype STRING The version type. Valid values are: a, b, c. Example: if version is 1.0.1, then a is 1, b is 0, c is 1." 
  echo "-m, --message STRING The check in message." 
}

# $OPTARG to get arg value
# $OPTIND to get index
# Currently donot support long parameter
while getopts "r:f:v:m:" option  
do   
    case "$option" in   
    	f)  
            podspecFile=$OPTARG
            ;;  

        file)  
            podspecFile=$OPTARG
            ;; 
        v)  
            build_version_type=$OPTARG
            ;;  

        versiontype)  
            build_version_type=$OPTARG
            ;;  

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


################# Util function ############################
function outputArr() {
	arg_list=$*
	echo "\$*='$*'"
	for arg in $arg_list
	do
		echo "[$arg]"
	done
}
################# End Util function ############################


################# Version function ############################
function getPodVersionLine() {
	local podspecFile=$1
	local findPodVersion="$(awk '/s.version *=/ { \
		print $0; \
	}' ${podspecFile})"

	#s.version      = "1.0.20" -> s.version="1.0.20"
	findPodVersion="$(echo "$findPodVersion" | sed -E 's/ *//g')"
	echo "${findPodVersion}"
}

function getPodVersionKey() {
	OLD_IFS="$IFS"
	IFS="="
	local versionLine=($1)
	IFS="$OLD_IFS"
	
	#outputArr $versionLine
	#s.version
	local podVersionKey=${versionLine[0]}

	echo ${podVersionKey}
}

function getPodVersionValue() {
	OLD_IFS="$IFS"
	IFS="="
	local versionLine=($1)
	IFS="$OLD_IFS"
	
	#outputArr $versionLine
	#"1.0.20"
	local podVersion=${versionLine[1]}
	#"1.0.20" -> 1.0.20"
	podVersion=${podVersion#*\"}
	#1.0.20" -> 1.0.20
	podVersion=${podVersion%*\"}

	echo ${podVersion}
}

function incVersion() {
	OLD_IFS="$IFS"
	IFS="."
	local version=($1)
	IFS="$OLD_IFS"
	build_version_type=$2

	if [[ $build_version_type = $c_build_version ]]; then
		version[2]=`expr 1 + ${version[2]}`
	elif [[ $build_version_type = $b_build_version ]]; then
		version[1]=`expr 1 + ${version[1]}`
		version[2]=0
	elif [[ $build_version_type = $a_build_version ]]; then
		version[0]=`expr 1 + ${version[0]}`
		version[1]=0
		version[2]=0
	fi

	echo "${version[0]}.${version[1]}.${version[2]}"
}

################# End version function ############################

################# Git function ############################
function checkInAndMakeTag() {
	local newVersion=$1
	local checkInMessage=$2

	if [[ $checkInMessage = "" ]]; then
		checkInMessage="update to new version ${newVersion}"
	fi

	git add .
	git commit -m "${checkInMessage}"
	git tag ${newVersion}
	git push origin master --tags
}

################# End git function ############################

################ Upload function ############################
function upload() {
	local podspecFile=$1
	pod trunk push ${podspecFile} --verbose --allow-warnings
}

################# End upload function ############################

################# Main function ############################
function checkParams() {
	if [[ ${podspecFile} = "" ]]; then
		usage
		exit
	fi
}

function start() {
	checkParams
	
	podspecFile=${podspecFile}
	podVersionLine=`getPodVersionLine ${podspecFile}`
	versionKey=`getPodVersionKey $podVersionLine`

	version=`getPodVersionValue $podVersionLine`
	echo "version $version"

	newVersion=`incVersion $version $build_version_type`
	echo "update to new version $newVersion"

	#replace string and modify pod spec file
	sed -i '' "s/${versionKey} *= *\"${version}\"/${versionKey}      = \"${newVersion}\"/g"  ${podspecFile}

	checkInAndMakeTag ${newVersion} ${checkInMessage}
	upload ${podspecFile}
}

start
################# End Main function ############################




