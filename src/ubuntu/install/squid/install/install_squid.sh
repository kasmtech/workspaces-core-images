#!/bin/bash
set -ex

ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')

# intall squid
SQUID_COMMIT='de1dffbc94d4132d6c696de8c6dfcd6f08900f61'
SQUID_DISTRO=${DISTRO}
# currently all distros use the ubuntu build of squid except centos/oracle
if [[ "${SQUID_DISTRO}" != @(centos|oracle7) ]] ; then
  SQUID_DISTRO="ubuntu"
fi
if [ "${DISTRO}" == "oracle7" ]; then
  SQUID_DISTRO=centos
  DISTRO=centos
elif [ "${DISTRO}" == "oracle8" ]; then
  SQUID_DISTRO=oracle8
  DISTRO=oracle
elif [ "${DISTRO}" == "opensuse" ]; then
  SQUID_DISTRO=opensuse
fi
if  $(grep -q Jammy /etc/os-release) || $(grep -q Kali /etc/os-release) ; then
  apt-get update
  apt-get install -y squid-openssl
  mkdir -p /usr/local/squid/sbin
  mkdir -p /usr/local/squid/var/logs/
  ln -s /usr/lib/squid/ /usr/local/squid/libexec
  ln -s /usr/sbin/squid /usr/local/squid/sbin/squid
elif [[ "${SQUID_DISTRO}" != @(centos|oracle7|oracle8|opensuse) ]] ; then
  wget -qO- "https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_${SQUID_DISTRO}_${ARCH}.tar.gz" | tar -xzf - -C /
fi

# update squid conf with user info
if [[ "${DISTRO}" == @(centos|oracle) ]]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
elif [ "${DISTRO}" == "opensuse" ]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
  groupadd -g 65511 proxy
  usermod -a -G proxy proxy
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


if [[ "${DISTRO}" == "centos" ]]; then
  yum install -y memcached cyrus-sasl iproute
elif [ "${DISTRO}" == "oracle" ]; then
  dnf install -y memcached cyrus-sasl iproute
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn memcached cyrus-sasl iproute2 libatomic1
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

KASM_SQUID_ADAPTER=https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/d54ebc03a8696964b12cb99e5863116fb3a26c0b/kasm_squid_adapter_${DISTRO/kali/ubuntu}_${ARCH}_develop.d54ebc.tar.gz

wget -qO- ${KASM_SQUID_ADAPTER} | tar xz -C /etc/squid/
ls -la /etc/squid
chmod +x /etc/squid/kasm_squid_adapter

# FIXME - This likely should be moved somewhere else to be more explicit
# Install Cert utilities
if [[ "${DISTRO}" == "centos" ]]; then
  yum install -y nss-tools
elif [ "${DISTRO}" == "oracle" ]; then
  dnf install -y nss-tools
  dnf clean all
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn mozilla-nss-tools
  zypper clean --all
else
  apt-get install -y libnss3-tools
  apt-get clean -y
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
