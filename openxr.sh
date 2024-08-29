#!/usr/bin/env cached-nix-shell 
#!nix-shell -i bash -p bash -p patchelf
VRCLIENT=~/.local/share/Steam/steamapps/common/SteamVR/bin/linux64/vrclient.so
STOREPATH=$(nix-store -qR `which steam` | grep steam-fhs)/lib64
patchelf --set-rpath $STOREPATH $VRCLIENT
