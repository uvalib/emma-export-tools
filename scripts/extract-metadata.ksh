#!/usr/bin/env bash
#
# EMMA metadata extract script
#

#set -x

# source common helpers
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <output directory>"
}

# ensure correct usage
if [ $# -lt 1 ]; then
   show_use_and_exit
fi

# input parameters for clarity
OUTPUT_DIR=${1}

# check the output directory exists
ensure_dir_exists ${OUTPUT_DIR}

# other definitions
RAW_FILE=/tmp/emma-extract.$$

# tool for extract
PG_TOOL=${SCRIPT_DIR}/pg_query.ksh
ensure_file_exists ${PG_TOOL}

# ensure our environment definitions are available
ensure_var_defined "${DBHOST}" "DBHOST"
ensure_var_defined "${DBPORT}" "DBPORT"
ensure_var_defined "${DBUSER}" "DBUSER"
ensure_var_defined "${DBPASS}" "DBPASS"
ensure_var_defined "${DBNAME}" "DBNAME"

# do the extract
${PG_TOOL} ${DBHOST} ${DBPORT} ${DBUSER} ${DBPASS} ${DBNAME} "select id, submission_id, emma_data, file_data from entries order by id" > ${RAW_FILE}

# track our progress
SUCCESS_COUNT=0

# go through each one
IFS=$'\n'
for line in $(<${RAW_FILE}); do

   id=$(echo ${line} | awk -F'|' '{print $1}' | awk '{print $1}')
   sub_id=$(echo ${line} | awk -F'|' '{print $2}' | awk '{print $1}')
   echo "Processing ${sub_id}..."
   echo ${sub_id} > ${OUTPUT_DIR}/submission-id.${id}
   echo ${line} | awk -F'|' '{print $3}' > ${OUTPUT_DIR}/emma-data.${id}
   echo ${line} | awk -F'|' '{print $4}' > ${OUTPUT_DIR}/file-data.${id}

   ((SUCCESS_COUNT=SUCCESS_COUNT+1))
done

rm ${RAW_FILE}

# status message
echo "done... ${SUCCESS_COUNT} successful, 0 error(s)"

# its all over
exit 0

#
# end of file
#
