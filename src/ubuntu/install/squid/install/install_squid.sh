#!/bin/bash
set -ex

# Install openssl
ARCH=$(arch | sed 's/aarch64/arm64/g' | sed 's/x86_64/amd64/g')
if [[ "${DISTRO}" == @(centos|oracle7|oracle8|oracle9|fedora37|fedora38|fedora39|fedora40|almalinux8|almalinux9|rockylinux8|rockylinux9) ]]; then
  dnf install -y openssl xkbcomp
  rm -f /etc/X11/xinit/xinitrc
if [[ "${DISTRO}" == "rhel9" ]]; then
  dnf install -y openssl
elif [[ "${DISTRO}" == "alpine" ]]; then
  apk add --no-cache openssl
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn openssl
else
  apt-get update
  apt-get install -y openssl
fi

# Intall squid
SQUID_COMMIT='c45537169794a16029e06d7d456edb21b9ce7d12'
if $(grep -q Focal /etc/os-release) || $(grep -q bullseye /etc/os-release) || [ -f /usr/bin/zypper ] || [[ "${DISTRO}" == @(oracle8|almalinux8|rockylinux8) ]]; then
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_ubuntu11_${ARCH}.tar.gz | tar -xzf - -C /
elif [[ "${DISTRO}" == "alpine" ]]; then
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_alpine_${ARCH}.tar.gz | tar -xzf - -C /
else
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm-squid-builder/${SQUID_COMMIT}/output/kasm-squid-builder_ubuntu_${ARCH}.tar.gz | tar -xzf - -C /
fi

# Update squid conf with user info
if [[ "${DISTRO}" == @(centos|oracle7|oracle8|oracle9|fedora37|fedora38|fedora39|fedora40|almalinux8|almalinux9|rockylinux8|rockylinux9|alpine|rhel9) ]]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
elif [ "${DISTRO}" == "opensuse" ]; then
  useradd --system --shell /usr/sbin/nologin --home-dir /bin proxy
  groupadd -g 65511 proxy
  usermod -a -G proxy proxy
fi

# File and perms
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


if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum install -y memcached cyrus-sasl iproute
elif [[ "${DISTRO}" == @(oracle8|fedora37|fedora38|fedora39|fedora40|oracle9|rhel9|rockylinux9|rockylinux8|almalinux9|almalinux8) ]]; then
  dnf install -y memcached cyrus-sasl iproute
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn memcached cyrus-sasl iproute2 libatomic1
elif [[ "${DISTRO}" == "alpine" ]]; then
  apk add --no-cache memcached cyrus-sasl iproute2 libatomic
else
  apt-get install -y memcached sasl2-bin libsasl2-modules iproute2
fi

# Enable SASL in the memchache config
echo "-S" >> /etc/memcached.conf

mkdir -p /etc/sasl2
cat >>/etc/sasl2/memcached.conf <<EOL
mech_list: plain
log_level: 5
sasldb_path: /etc/sasl2/memcached-sasldb2
EOL


COMMIT_ID="456fe95221c5e0cba5b10f2913a36cf85eaa3f23"
BRANCH="develop"
COMMIT_ID_SHORT=$(echo "${COMMIT_ID}" | cut -c1-6)


if [[ "${DISTRO}" == "alpine" ]]; then
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/${COMMIT_ID}/kasm_squid_adapter_alpine_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar xz -C /etc/squid/
else
  wget -qO- https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/${COMMIT_ID}/kasm_squid_adapter_glibc_${ARCH}_${BRANCH}.${COMMIT_ID_SHORT}.tar.gz | tar xz -C /etc/squid/
fi
echo "${BRANCH}:${COMMIT_ID}" > /etc/squid/kasm_squid_adapter.version
ls -la /etc/squid
chmod +x /etc/squid/kasm_squid_adapter

# FIXME - This likely should be moved somewhere else to be more explicit
# Install Cert utilities
if [[ "${DISTRO}" == @(centos|oracle7) ]]; then
  yum install -y nss-tools
elif [[ "${DISTRO}" == @(oracle8|fedora37|fedora38|fedora39|fedora40|oracle9|rhel9|rockylinux9|rockylinux8|almalinux9|almalinux8) ]]; then
  dnf install -y nss-tools
elif [ "${DISTRO}" == "opensuse" ]; then
  zypper install -yn mozilla-nss-tools
elif [ "${DISTRO}" == "alpine" ]; then
  apk add --no-cache nss-tools
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
