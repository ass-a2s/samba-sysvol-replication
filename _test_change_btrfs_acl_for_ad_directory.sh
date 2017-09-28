#!/bin/sh

### LICENSE - (BSD 2-Clause) // ###
#
# Copyright (c) 2016, Daniel Plominski (ASS-Einrichtungssysteme GmbH)
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification,
# are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright notice, this
# list of conditions and the following disclaimer in the documentation and/or
# other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
# ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
### // LICENSE - (BSD 2-Clause) ###

### ### ### ASS ### ### ###

setacl(){
    #// clean up acls
    setfacl --remove-all "$@"

    #// set freenas-admin:domain\ admins
    chown 3000000:users "$@"
    chmod 0770 "$@"

    #// set ad permissions (domain\ users rx)
    setfacl -m "user:3000000:rwx" "$@"
    setfacl -m "user:3000017:rwx" "$@"
    setfacl -m "user:3000100:rwx" "$@"

    setfacl -m "group::r-x" "$@"
    setfacl -m "group:users:r-x" "$@"
    setfacl -m "group:3000017:rwx" "$@"
    setfacl -m "group:3000100:rwx" "$@"
    setfacl -m "other::---" "$@"

    setfacl -m "default:user::rwx" "$@"
    setfacl -m "default:user:3000000:rwx" "$@"
    setfacl -m "default:user:3000017:rwx" "$@"
    setfacl -m "default:user:3000100:rwx" "$@"

    setfacl -m "default:group::---" "$@"
    setfacl -m "default:group:users:r-x" "$@"
    setfacl -m "default:group:3000017:rwx" "$@"
    setfacl -m "default:group:3000100:rwx" "$@"
    setfacl -m "default:mask::rwx" "$@"
    setfacl -m "default:other::---" "$@"
}

### execute:

while getopts ":o:" opt; do
  case "$opt" in
    o) object=$OPTARG ;;
  esac
done
shift $(( OPTIND - 1 ))

#/ show usage
if [ -z "$object" ]; then
   echo "" # dummy
   echo "can't get file/directory object path" # dummy
   echo "" # dummy
   echo "usage:   ./change_btrfs_acl_for_ad_directory.sh -o (file or directory path)"
   exit 0
fi

setacl "$object"

### ### ### ASS ### ### ###
exit 0
# EOF
