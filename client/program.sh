#!/bin/bash
set -e


#variables
basedir="${0%/*}"
script_name="${0##*/}"
ip="localhost"

#function print on the screen 
error(){
	[ "${quite_flag}" = "y" ] || echo -e 1>&2 "Error: $@" 
	exit 1
}

log(){
	[ "${quite_flag}" = "y" ] || echo -e 1>&2 "$@"
	return 0
}
#untility requirements
getopt --version 1>/dev/null 2>&1 || error "getopts not found."
curl --version 1>/dev/null 2>&1 || error "curl not found."

#flags
quite_flag="n"
download_flag="n"
adduser_flag="n"
upload_flag="n"
#variables
path="."
file=""
username=""
password=""


#need to check if the getopt and curl exsist in the users... 

short_opts="qhdauf:n:p:o:"
long_opts="help,quite,download,upload,adduser,output:,file:,name:,password:"

getopt=$(getopt -n "${script_name}" -o "${short_opts}" -l "${long_opts}" -- "$@")
eval set -- "${getopt}"

while true ; do
	case "$1" in
		-h|--help) echo "
		 Cloud Project .
		----------------

		Commands :
		---------
		-h (help) | -q (quite) | -d (download) | -u (upload) | -a (adduser) | -p (password) | -f (file) | -o (output)


		-h | --help                 )    print this synopsis .
		-q | --quite                )    not print output to the screen .
		-d | --download             )    this flag , means that actions you take it download .
		-u | --upload               )    this flag , means that actions you take it upload .
		-a | --adduser 		    )	 this flag , means that actions you take it add user  .
		-n | --name	<username>  )    your username .
		-p | --password <Password>  )    your password .
		-f | --file     <file>      )    the file you want to download or upload to the server .
		-o | --output 	<Path>      )    where to download to specific location (default current location)
		----------------------------------------------------------------------------------------------

		examples :
		---------
		add user :
		<nameScrip> (-a | --adduser) (-n | --name) <username> (-p | password) <password>

		upload file :
		<nameScrip> (-u | --upload) (-n | --name) <username> (-p | password) <password>  (-f | --file) <file>

		download file :
	        <nameScrip> (-d | --download) (-n | --name) <username> (-p | password) <password>  (-f | --file) <file> (-o | --output) <location to download>
		-------------------------------------------------------------------------------------------------------

		this program was written by :
						Shmuel Uzan   .
						Arnold Osipov .
		"
			  exit ;;
		-q|--quite)
			quite_flag="y"
			shift ;;
		-d|--download)
			download_flag="y"
#			echo  "${download_flag}"
			shift ;;
		-u|--upload)
			upload_flag="y"
#			echo "${upload_flag}"
			shift ;;
		-a|--adduser)
			adduser_flag="y"
#			echo "${adduser_flag}"
			shift ;;
		-f|--file)
			file="$2"
			file_name="${file##*/}"
#			echo "${file}"
			shift 2 ;;
		-n|--name)
			username="$2"
#			echo "${username}"
			shift 2 ;;
		-p|--password)
			password="$2"
#			echo "${password}"
			shift 2 ;;
		-o| --output)
			path="$2"
			echo "${path}"
			shift 2;;
		--)
			shift 1 ;
			break ;;
		*)
			error "Invalid option - unknown parameter $1" ;;
	esac
done

if [ "${upload_flag}" = y ] ; then
	if [ -e "${file}" ] ; then 
		log "uploading a file."
		curl --data-binary @${file} "${ip}/upload/?${username}&${password}&${file_name}&"
	else
		log "${file_name} : not exsist."
	fi
elif [ "${adduser_flag}" = y ] ; then
	log "creating a new user"
	curl "${ip}/adduser/?${username}&${password}&"

elif [ "${download_flag}" = y ] ; then
	log "downloading a file."
	file_exsist="false"
	if [ -d "${path}/temp" ] ; then
		echo "exsist temp"
		file_exsist="true"
	else
		echo "not exsist"
		mkdir "${path}/temp"

	fi

	curl -o "${path}/temp/${file_name}.bak" "${ip}/download/?${username}&${password}&${file_name}&"
	if [ "$(head -n 1 ${path}/temp/${file_name}.bak)" = "Status:400" ] ; then
#		echo "Delete File"
		head -n 1 "${path}/temp/${file_name}.bak"

		if [ "${file_exsist}" = "true" ] ; then
			echo "${file_exsist}"
			rm -r "${path}/temp/${file_name}.bak"
		else
			rm -r "${path}/temp"
		fi

		error "File not exsist..."
	else
		cp "${path}/temp/${file_name}.bak" "${path}/${file_name}"
                if [ "${file_exsist}" = "true" ] ; then
                        rm -r "${path}/temp/${file_name}.bak"
                else
                        rm -r "${path}/temp"
                fi

		log "download succeeded.."
	fi

fi;

