#!/usr/bin/env bash
#
# A helper to issue a Postgres query
#

#set -x

# source common helpers
#FULL_NAME=$(realpath $0)
SCRIPT_DIR=$( (cd -P $(dirname $0) && pwd) )
#SCRIPT_DIR=$(dirname $FULL_NAME)
. $SCRIPT_DIR/common.ksh

function show_use_and_exit {
   error_and_exit "use: $(basename $0) <host> <port> <user> <password> <database> <query>"
}

# ensure correct usage
if [ $# -lt 6 ]; then
   show_use_and_exit
fi

# input parameters for clarity
DBHOST=$1
shift
DBPORT=$1
shift
DBUSER=$1
shift
DBPASSWD=$1
shift
DBNAME=$1
shift
DBQUERY=$*
shift

# ensure the necessary tools exist
QUERY_TOOL=psql
ensure_tool_available $QUERY_TOOL

# issue the query
PGPASSWORD=$DBPASSWD $QUERY_TOOL -h $DBHOST -p $DBPORT -U $DBUSER -d $DBNAME -t -c "$DBQUERY"
exit_on_error $? "Issue query failed with error $?"

# success
exit 0

#
# end of file
#
