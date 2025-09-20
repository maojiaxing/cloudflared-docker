#!/usr/bin/env sh

if [ "$(id -u)" -ne 0 ]; then
  echo "reboot: Need to be root"
  exit 1
fi

sudo kill -SIGTERM 1
