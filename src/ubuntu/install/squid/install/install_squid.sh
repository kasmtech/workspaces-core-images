# update squid conf with user info
set -ex

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


if [ "$DISTRO" = centos ]; then
  KASM_SQUID_ADAPTER=https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/f06293b2e585dbee75728e84293fe61386289c27/kasm_squid_adapter_centos_feature_KASM-1474_centos_build.f06293.tar.gz
else
  KASM_SQUID_ADAPTER=https://kasmweb-build-artifacts.s3.amazonaws.com/kasm_squid_adapter/1cc3b450ee0bfb1aa76a0c3330f8d6e86b365448/kasm_squid_adapter_develop.1cc3b4.tar.gz
fi
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
