#!/usr/bin/env bash
set -e
if [[  -z "${http_proxy_address}" || -z "${http_proxy_port}"  ]]; then
  echo "proxy configs not set"
else
    if [ -d $HOME/.mozilla/firefox/kasm/ ]; then
        echo "Found default firefox profile. Setting Firefox proxy configurations"
        out="$HOME/.mozilla/firefox/kasm/user.js"
        echo "user_pref(\"network.proxy.http\", \"${http_proxy_address}\");" >> $out
        echo "user_pref(\"network.proxy.http_port\", ${http_proxy_port});" >> $out
        echo "user_pref(\"network.proxy.type\", 1);" >> $out
        echo "user_pref(\"network.proxy.backup.ftp\", \"\");" >> $out
        echo "user_pref(\"network.proxy.backup.ftp_port\", 0);" >> $out
        echo "user_pref(\"network.proxy.backup.socks\", \"\");" >> $out
        echo "user_pref(\"network.proxy.backup.socks_port\", 0);" >> $out
        echo "user_pref(\"network.proxy.backup.ssl\", \"\");" >> $out
        echo "user_pref(\"network.proxy.backup.ssl_port\", 0);" >> $out
        echo "user_pref(\"network.proxy.ftp\", \"${http_proxy_address}\");" >> $out
        echo "user_pref(\"network.proxy.ftp_port\", ${http_proxy_port});" >> $out
        echo "user_pref(\"network.proxy.http\", \"${http_proxy_address}\");" >> $out
        echo "user_pref(\"network.proxy.http_port\", ${http_proxy_port});" >> $out
        echo "user_pref(\"network.proxy.share_proxy_settings\", true);">> $out
        echo "user_pref(\"network.proxy.socks\", \"${http_proxy_address}\");" >> $out
        echo "user_pref(\"network.proxy.socks_port\", ${http_proxy_port});" >> $out
        echo "user_pref(\"network.proxy.ssl\", \"${http_proxy_address}\");" >> $out
        echo "user_pref(\"network.proxy.ssl_port\", ${http_proxy_port});">> $out
        echo "user_pref(\"network.proxy.type\", 1);" >> $out
    fi
fi


if [[  -z "${browser_startup_url}"  ]]; then
  echo "browser_startup_url not set"
else
    if [ -d $HOME/.mozilla/firefox/kasm/ ]; then
        echo "Found default firefox profile. Setting Firefox startup url settings"
        out="$HOME/.mozilla/firefox/kasm/user.js"
        echo "user_pref(\"browser.startup.homepage\", \"${browser_startup_url}\");" >> $out
        # Disable all the firefox firstrun and welcome tabs
        echo "user_pref(\"browser.startup.firstrunSkipsHomepage\", false);" >> $out
        echo "user_pref(\"toolkit.telemetry.reportingpolicy.firstRun\", false);" >> $out
        echo "user_pref(\"browser.startup.homepage_override.mstone\", \"ignore\");" >> $out
    fi
fi