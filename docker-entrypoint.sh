#!/bin/sh
set -e

echo "[builder] Building some awesomeness. Fasten your seatbelt."

# Set the locale. UTF-8 required by erlang vm
# export ENV LANG=en_US.UTF-8
# export ENV LC_ALL=en_US.UTF-8

if [ -z $VERSION ]; then
  echo "[builder] Missing env: Must set VERSION"; exit 1;
fi
if [ -z $REPO_URL ]; then
  echo "[builder] Missing env: Must set REPO_URL"; exit 1;
fi
if [ -z $PORT ]; then
 PORT=4000
fi
if [ -z $S3_BUCKET ]; then
  echo "Must supply S3_BUCKET environment variable."; exit 1;
fi
if [[ $DEBUG ]] && [[ "$DEBUG" -eq 1 ]]; then
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

echo "[builder] Precompile static assets"
MIX_ENV=prod mix phoenix.digest

echo "[builder] Compiling application"
MIX_ENV=prod mix release.clean

echo "[builder] Building release into /root/app"
MIX_ENV=prod mix release

echo "[builder] Autodetecting app name"
APP_NAME=`ls /root/app/rel/`

echo "[builder] Uploading the release to S3 bucket $S3_BUCKET"
aws s3 cp /root/app/rel/$APP_NAME/releases/$VERSION/$APP_NAME.tar.gz s3://$S3_BUCKET/releases/$APP_NAME-$VERSION.tar.gz

echo "[builder] Done! Your application has been uploaded to s3://$S3_BUCKET.s3.amazonaws.com/releases/$APP_NAME-$VERSION.tar.gz"

echo "[builder] Starting iex console to test that the app will boot"
echo "[builder] WARNING: if your app has a database this console is connected"
echo "[builder]   to the database. Tread lightly"

exec /root/app/rel/$APP_NAME/bin/$APP_NAME console

