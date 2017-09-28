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

#// FUNCTION: spinner (Version 1.0)
spinner() {
   local pid=$1
   local delay=0.01
   local spinstr='|/-\'
   while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
         local temp=${spinstr#?}
         printf " [%c]  " "$spinstr"
         local spinstr=$temp${spinstr%"$temp"}
         sleep $delay
         printf "\b\b\b\b\b\b"
   done
   printf "    \b\b\b\b"
}

#// FUNCTION: run script as root (Version 1.0)
checkrootuser() {
if [ "$(id -u)" != "0" ]; then
   echo "[ERROR] This script must be run as root" 1>&2
   exit 1
fi
}

#// FUNCTION: check state (Version 1.0)
checkhard() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;31mFAILED\033[0m\n")] '"$@"'"
   sleep 1
   exit 1
fi
}

#// FUNCTION: check state without exit (Version 1.0)
checksoft() {
if [ $? -eq 0 ]
then
   echo "[$(printf "\033[1;32m  OK  \033[0m\n")] '"$@"'"
else
   echo "[$(printf "\033[1;33mFAILED\033[0m\n")] '"$@"'"
   sleep 1
fi
}

#// FUNCTION: check state hidden (Version 1.0)
checkhiddenhard() {
if [ $? -eq 0 ]
then
   return 0
else
   #/return 1
   checkhard "$@"
   return 1
fi
}

#// FUNCTION: check state hidden without exit (Version 1.0)
checkhiddensoft() {
if [ $? -eq 0 ]
then
   return 0
else
   #/return 1
   checksoft "$@"
   return 1
fi
}

#// FUNCTION: drs over ssh port 222
drs() {
   #// remove old remote sysvol
   echo "remove old sysvol on remote host: '"$@"'"
   ssh -p 222 root@"$@" "rm -rf /var/lib/samba/sysvol/assdomain.intern"
   checksoft remove old sysvol on the remote dc
   sleep 2
   #// transfer sysvol
   echo "transfering new sysvol to remote host: '"$@"'"
   scp -P 222 -r /var/lib/samba/sysvol/assdomain.intern root@"$@":/var/lib/samba/sysvol
   checksoft transfer dc1 sysvol to remote dc
   sleep 2
   #// remote - samba-tool ntacl sysvolreset
   echo "prepare: samba-tool ntacl sysvolreset on remote host: '"$@"'"
   ssh -p 222 root@"$@" "samba-tool ntacl sysvolreset"
   checksoft samba-tool ntacl sysvolreset on remote dc
   sleep 5
   #// remote - samba-tool ntacl sysvolcheck
   ssh -p 222 root@"$@" "samba-tool ntacl sysvolcheck"
   checksoft samba-tool ntacl sysvolcheck on remote dc
   sleep 5
   #// remote - samba stop
   ssh -p 222 root@"$@" "systemctl stop samba-ad-dc.service"
   checksoft samba stop on remote dc
   sleep 5
   #// remote - samba start
   ssh -p 222 root@"$@" "systemctl start samba-ad-dc.service"
   checksoft samba start on remote dc
   sleep 5
   #// remote - samba status
   ssh -p 222 root@"$@" "systemctl --no-pager status samba-ad-dc.service"
   checksoft samba status on remote dc
   sleep 5
}
   
#// SCRIPT:

checkrootuser

SYSVOLWATCH=$(find /var/lib/samba/sysvol -mtime -1 | grep -c "")
if [ "$SYSVOLWATCH" = "0" ]
then
   echo "nothing to do"
else
   #// set current time
   (find /var/lib/samba/sysvol | xargs -L 1 -I % touch %) & spinner $!
   checksoft set current time on sysvol
   sleep 1
   #// clean up TMP files
   (find /var/lib/samba/sysvol -type f -name "*.tmp" -exec rm -fv {} \;) & spinner $!
   checksoft clean up TMP files on sysvol
   sleep 1
   #// samba-tool ntacl sysvolreset
   echo "prepare: samba-tool ntacl sysvolreset"
   (samba-tool ntacl sysvolreset) & spinner $!
   checksoft samba-tool ntacl sysvolreset
   sleep 1
   #// samba-tool ntacl sysvolcheck
   (samba-tool ntacl sysvolcheck) & spinner $!
   checksoft samba-tool ntacl sysvolcheck
   sleep 5
   #// samba stop
   (systemctl stop samba-ad-dc.service) & spinner $!
   checksoft samba stop
   sleep 5
   #// samba start
   (systemctl start samba-ad-dc.service) & spinner $!
   checksoft samba start
   sleep 5
   #// samba status
   (systemctl --no-pager status samba-ad-dc.service) & spinner $!
   checksoft samba status
   sleep 5

   #// drs to edv-dc2-vm
   sleep 15
   (drs edv-dc2-vm.assdomain.intern) & spinner $!
   checksoft drs to edv-dc2-vm
   sleep 15

   #// drs to edv-dc3-vm
   sleep 15
   (drs edv-dc3-vm.assdomain.intern) & spinner $!
   checksoft drs to edv-dc3-vm
   sleep 15

fi

### ### ### ASS ### ### ###
exit 0
# EOF
