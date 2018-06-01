#!/usr/bin/env bash

# Usage: 
# $ .travis.decrypt.sh <rsa-file-destination>
#
# Takes an encrypted file, unencrypts it and splits it in two.
#
# This script assumes that said file, when unencrypted, contains two sections:
#
# 1. A script containing environment variables definitions (export VAR="value")
# 2. A private RSA key that Travis will use to perform passwordless SSH authentication. 
#    This file will be stored in the location given as a first positional argument
#    to this script.
#
# The two sections are separated by a "file separator", which is a 
# single line (see FILE_SEPARATOR variable down below).
#

# 1st argument: location on which we will store the RSA private key
RSA_PRIVATE_KEY_DESTINATION=$1

# location on which we will unencrypt the file
UNENCRYPTED_FILE_DESTINATION="/tmp/travis_deployment_key"
# file separator
FILE_SEPARATOR="###-#-#-#-qbic-quick-and-dirty-file-separator-#-#-#-###"

## IMPORTANT: the variables starting with "encrypted_..." are different for every repository, make sure you edit this line
openssl aes-256-cbc -K $encrypted_c9fdf0a9e647_key -iv $encrypted_c9fdf0a9e647_iv -in travis_deployment_key.enc -out $UNENCRYPTED_FILE_DESTINATION -d

# find in which line is our file separator
FILE_SEPARATOR_LINE=`grep --line-number "$FILE_SEPARATOR" $UNENCRYPTED_FILE_DESTINATION | cut --fields 1 --delimiter=:`

# we know that the first part contains a script that will set all required environment variables, we just source it as-is
source <(head --lines $(( $FILE_SEPARATOR_LINE - 1 )) $UNENCRYPTED_FILE_DESTINATION)

# the second part of the unencrypted file contains a private key, output the last part of the unencrypted file into the desired destination
tail --lines +$(( $FILE_SEPARATOR_LINE + 1 )) $UNENCRYPTED_FILE_DESTINATION > $RSA_PRIVATE_KEY_DESTINATION
# make sure to change file permissions on this very special file
chmod 600 $RSA_PRIVATE_KEY_DESTINATION

# remove the unencrypted file
rm -f $UNENCRYPTED_FILE_DESTINATION