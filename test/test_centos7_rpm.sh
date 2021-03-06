#!/bin/bash

function error {
  echo $1
  exit 1
}

yum install -y yum-utils

# Check rpm's md5sum
mkdir rpms
tar -zxvf in/$RPM_FILE_NAME -C rpms

rpm_md5sum="$(rpm -Kv rpms/rippled-[0-9]*.x86_64.rpm | grep 'MD5 digest' | grep -oP '\(\K[^)]+')"
dbg_md5sum="$(rpm -Kv rpms/rippled-debuginfo*.x86_64.rpm | grep 'MD5 digest' | grep -oP '\(\K[^)]+')"
src_md5sum="$(rpm -Kv rpms/rippled*.src.rpm | grep 'MD5 digest' | grep -oP '\(\K[^)]+')"

rpm_sha256="$(sha256sum rpms/rippled-[0-9]*.x86_64.rpm | awk '{ print $1}')"
dbg_sha256="$(sha256sum rpms/rippled-debuginfo*.x86_64.rpm | awk '{ print $1}')"
src_sha256="$(sha256sum rpms/rippled*.src.rpm | awk '{ print $1}')"

if [ "$RPM_MD5SUM" != "$rpm_md5sum" ] || \
   [ "$DBG_MD5SUM" != "$dbg_md5sum" ] || \
   [ "$SRC_MD5SUM" != "$src_md5sum" ] || \
   [ "$RPM_SHA256" != "$rpm_sha256" ] || \
   [ "$DBG_SHA256" != "$dbg_sha256" ] || \
   [ "$SRC_SHA256" != "$src_sha256" ]
then
  echo -e "\nChecksum failed!"
  echo -e "\nExiting....."
  exit 1
else
  echo -e "\nChecksum passed!"
fi

rpm -Uvh --nodeps rpms/rippled-*.x86_64.rpm
rc=$?; if [[ $rc != 0 ]]; then
  error "error installing rippled-$RIPPLED_VERSION rpm from $YUM_REPO"
fi

if [ ! -f /opt/ripple/etc/rippled.cfg ] || \
   [ ! -f /opt/ripple/etc/validators.txt ] || \
   [ ! -f /etc/opt/ripple/rippled.cfg ] || \
   [ ! -f /etc/opt/ripple/validators.txt ]
then
    echo "\nMissing config file"
    exit 1
fi

/opt/ripple/bin/rippled --unittest
rc=$?; if [[ $rc != 0 ]]; then
  error "rippled --unittest failed"
fi

/opt/ripple/bin/validator-keys --unittest
rc=$?; if [[ $rc != 0 ]]; then
  error "validator-keys --unittest failed"
fi
