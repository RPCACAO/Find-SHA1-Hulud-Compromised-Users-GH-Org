#!/usr/bin/env bash

# set functions
timestamp() {
    date +"%Y%m%d%H%M%S"
}

debug() {
  if [[ ${DEBUG} == 1 ]]; then
    echo "$1"
  fi
}

PrintUsage()
{
  cat <<EOM
Usage: ${0} <file> [options]

Options:
    -h, --help                    : Show script help
    -d, --debug                   : Enable Debug logging
    -f, --file                    : The import file of list of users to scan

Description:
Gets all repos in user personal repositories in the import file (-f) that contain Sha1-Hulud activity and outputs to a json.

Example:
 ${0} -f user-list.txt

EOM
  exit 0
}

# set vars
DEBUG=0
HAS_NEXT_PAGE=
EXPORT_FILE="all_sha1repos_$(timestamp).json"
CURSOR=""


# Read paramters passed
PARAMS=""
while (( "$#" )); do
  case "$1" in
    -h|--help)
      PrintUsage;
      ;;
    -d|--debug)
      DEBUG=1
      shift
      ;;
    -f|--file)
      IMPORT_FILE=$2
      shift
      ;;
    --) # end argument parsing
      shift
      break
      ;;
    -*) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
    *) # preserve positional arguments
  PARAMS="$PARAMS $1"
  shift
  ;;
  esac
done


# make sure we have an import file
if [ -z "${IMPORT_FILE}" ]; then
    echo "No import file was provided."
    exit 1;
elif [ ! -f "${IMPORT_FILE}" ]; then
    echo "Import file provided not found."
    exit 1;
fi


# create file
touch ${EXPORT_FILE}

while read USERNAME; do

        echo "Getting repos from ${USERNAME}..."

        # Authenticate to github to increase your rate limit to 5000 https://github.com/settings/tokens
        RESULT=$(curl -s -u <username>:<personal_access_token> https://api.github.com/users/${USERNAME}/repos)


        # exit if fail to get back response
        if [ $? -ne 0 ]; then
            echo "";
            echo "Curl error: $?";
            exit 1;
        fi

        debug "Query result: ${RESULT}";

        # store condition for debugging
        CONDITION="select( .description // \"-\" | contains(\"Sha1-Hulud\")) | pick(.html_url,.description)";
        debug "Using condition: '${CONDITION}'";
        # get each user detail
        echo "${RESULT}" | jq -r ".[] | ${CONDITION}" \
                >> ${EXPORT_FILE};


done < ${IMPORT_FILE}
