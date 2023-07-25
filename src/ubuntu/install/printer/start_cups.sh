#!/usr/bin/env bash
set -ex
{
    PRINTER_NAME=${KASM_PRINTER_NAME:-Kasm-Printer}

    echo "Starting cups"
    /usr/sbin/cupsd -f &
    until [[ "$(lpstat -r)" == "scheduler is running" ]]; do sleep 15; done

    echo "Creating a virtual printer: $PRINTER_NAME"
    lpadmin -p $PRINTER_NAME -E -v cups-pdf:/ -P /etc/cups/ppd/kasm.ppd

    echo "Done!"
} 2>&1 | tee /tmp/start_cups.log
