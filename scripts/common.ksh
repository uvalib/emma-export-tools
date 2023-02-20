#
# common helpers and definitions
#

# show the error message and exit
function error_and_exit {
   echo "$*" >&2
   exit 1
}

# exit if an error occurrs
function exit_on_error {
   local STATUS=$1
   local MESSAGE=$2
   if [ $STATUS -ne 0 ]; then
      error_and_exit "ERROR: $MESSAGE"
   fi
}

# ensure a required tool is available
function ensure_tool_available {

   local TOOL_NAME=$1
   which $TOOL_NAME > /dev/null 2>&1
   res=$?
   if [ $res -ne 0 ]; then
      error_and_exit "$TOOL_NAME is not available in this environment"
   fi
}

# ensure a directory exists
function ensure_dir_exists {
   local DIR=$1
   if [ ! -d $DIR ]; then
      error_and_exit "$DIR is not available"
   fi
}

# ensure a file exists
function ensure_file_exists {
   local FILE=$1
   if [ ! -f $FILE ]; then
      error_and_exit "$FILE is not available"
   fi
}

# check our AWS environment requirements
function check_aws_environment {

   ensure_var_defined "$AWS_ACCESS_KEY_ID" "AWS_ACCESS_KEY_ID"
   ensure_var_defined "$AWS_SECRET_ACCESS_KEY" "AWS_SECRET_ACCESS_KEY"
   ensure_var_defined "$AWS_DEFAULT_REGION" "AWS_DEFAULT_REGION"
}

# ensure a specific variable defined
function ensure_var_defined {
   local VAR_VALUE=$1
   local VAR_NAME=$2
   if [ -z "$VAR_VALUE" ]; then
      error_and_exit "$VAR_NAME is not defined"
   fi
}

#
# end of fle
#
