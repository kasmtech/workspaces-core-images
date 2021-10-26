#!/bin/bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

# intall squid
SQUID_COMMIT='6392f7dfb1040c67c0a5d5518abf508282523cc0'
SQUID_DISTRO=${DISTRO}
# currently all distros use the ubuntu build of squid except centos
if [ ! "${SQUID_DISTRO}" == "centos" ] ; then
  SQUID_DISTRO="ubuntu"
fi
wget -qO- "https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_${SQUID_DISTRO}_${ARCH}.tar.gz" | tar -xzf - -C /

# update squid conf with user info
if [ "$DISTRO" = centos ]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
fi

mkdir /usr/local/squid/etc/ssl_cert -p
chown proxy:proxy /usr/local/squid/etc/ssl_cert -R
chmod 700 /usr/local/squid/etc/ssl_cert -R
cd /usr/local/squid/etc/ssl_cert

/usr/local/squid/libexec/security_file_certgen -c -s /usr/local/squid/var/logs/ssl_db -M 4MB
chown proxy:proxy /usr/local/squid/var/logs/ssl_db -R

chown -R proxy:proxy /usr/local/squid -R

mkdir -p /etc/squid/

# Trick so we can auto re-direct blocked urls to a special page
cat >>/etc/squid/blocked.acl <<EOL
.access_denied
EOL
chown -R proxy:proxy /etc/squid/blocked.acl


if [ "$DISTRO" = centos ]; then
  yum install -y memcached cyrus-sasl iproute
else
  apt-get install -y memcached sasl2-bin iproute2
fi

# Enable SASL in the memchache config
echo "-S" >> /etc/memcached.conf

mkdir -p /etc/sasl2
cat >>/etc/sasl2/memcached.conf <<EOL
mech_list: plain
log_level: 5
sasldb_path: /etc/sasl2/memcached-sasldb2
EOL

KASM_SQUID_ADAPTER=https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/faec132e9797ebf09cfa58bd59b60c77b0b1a64b/kasm_squid_adapter_${DISTRO/kali/ubuntu}_${ARCH}_develop.faec13.tar.gz

wget -qO- ${KASM_SQUID_ADAPTER} | tar xz -C /etc/squid/
ls -la /etc/squid
chmod +x /etc/squid/kasm_squid_adapter

# FIXME - This likely should be moved somewhere else to be more explicit
# Install Cert utilities
if [ "$DISTRO" = centos ]; then
  yum install -y nss-tools
else
  apt-get install -y libnss3-tools
fi

# Create an empty cert9.db. This will be used by applications like Chrome
mkdir -p $HOME/.pki/nssdb/
certutil -N -d sql:$HOME/.pki/nssdb/ --empty-password
chown 1000:1000 $HOME/.pki/nssdb/


cat >/usr/bin/filter_ready <<EOL
#!/usr/bin/env bash
if [ "\${http_proxy}" == "http://127.0.0.1:3128" ] ;
then
    while netstat -lnt | awk '\$4 ~ /:3128/ {exit 1}'; do sleep 1; done
    echo 'filter is ready'
else
    echo 'filter is not configured'
fi

EOL
chmod +x /usr/bin/filter_ready
