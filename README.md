
Samba SysVol Replication
========================

* Script for SysVolume Replication from DC1 (with PDC FSMO) to DC2 and DC3
* require SSH pubkey for SCP copy

Errata
======
* 18.06.2016 - sometimes broken scp transfer

Usage
=====
```
    # ./samba_sysvol_repl.sh
```

Example
=======
```
root@edv-dc1-vm:/ass.de-git/samba-sysvol-replication# ./samba_sysvol_repl_noreboot.sh
[  OK  ] 'set current time on sysvol'
prepare: samba-tool ntacl sysvolreset
[  OK  ] 'samba-tool ntacl sysvolreset'
[  OK  ] 'samba-tool ntacl sysvolcheck'
[  OK  ] 'samba status'
remove old sysvol on remote host: 'edv-dc2-vm.assdomain.intern'
[  OK  ] 'remove old sysvol on the remote dc'
transfering new sysvol to remote host: 'edv-dc2-vm.assdomain.intern'
[  OK  ] 'transfer dc1 sysvol to remote dc'
prepare: samba-tool ntacl sysvolreset on remote host: 'edv-dc2-vm.assdomain.intern'

[|] ... ... ...
root@edv-dc1-vm:/ass.de-git/samba-sysvol-replication#
```

