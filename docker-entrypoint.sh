#!/bin/sh
set -e

echo "[builder] Building some awesomeness. Fasten your seatbelt."

# Set the locale. UTF-8 required by erlang vm
export ENV LANG=en_US.UTF-8
export ENV LC_ALL=en_US.UTF-8

if [ -z $VERSION ]; then
  echo "[builder] Missing env: Must set VERSION"; exit 1;
fi
if [ -z $REPO_URL ]; then
  echo "[builder] Missing env: Must set REPO_URL"; exit 1;
fi
if [ -z $DEBUG ]; then
  set -x
fi

# Create the directory that will hold the source code
mkdir -p /root/app
cd /root/app

# Clone the code from the repo
git clone $REPO_URL /root/app
# Get the specific version by the tag and put it into the local release branch
git checkout -b release $VERSION


echo "[builder] Installing hex and other dependencies"
mix local.hex --force
mix deps.get
mix local.rebar # required by poolboy
mix hex.info

echo "[builder] Cleaning old release files"
MIX_ENV=prod mix clean

echo "[builder] Compiling application"
MIX_ENV=prod mix compile

echo "[builder] Waiting for install or mix commands"
exec sleep 10000
