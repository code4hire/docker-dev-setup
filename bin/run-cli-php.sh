#!/usr/bin/env bash

# get the directory where the script is located
script_dir="$(dirname "$0")"

# include the script with all the functions
. "$script_dir/functions.sh"

call_php_cli_php "$@"
