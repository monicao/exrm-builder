#!/bin/sh
set -ex

if [ -z $PORT ]; then
 PORT=4000
fi

if [ -z $S3_BUCKET ]; then
  echo "Must supply S3_BUCKET environment variable."; exit 1;
fi


cd /root/app

echo "[builder] Installing hex and mix dependencies"
mix local.hex --force
mix deps.get
mix local.rebar # required by poolboy
mix hex.info

echo "[builder] Precompile static assets"
MIX_ENV=prod mix phoenix.digest

echo "[builder] Compiling application"
MIX_ENV=prod mix release.clean

echo "[builder] Building release into /root/app"
MIX_ENV=prod mix release

echo "  [builder] Autodetecting app name"
APP_NAME=`ls /root/app/rel/`

echo "[builder] Uploading the release to S3 bucket $S3_BUCKET"
aws s3 /root/app/rel/$APP_NAME/releases/$VERSION/$APP_NAME.tar.gz s3://$S3_BUCKET/releases/$APP_NAME-$VERSION.tar.gz

echo "[builder] Done! Your application has been uploaded to s3://$S3_BUCKET.s3.amazonaws.com/releases/$APP_NAME-$VERSION.tar.gz"

echo "[builder] Starting iex console to test that the app will boot"
echo "[builder] WARNING: Do not close the iex console until the deploy is finished"
echo "[builder]   You will have to use this container later to run mix tasks"
echo "[builder]   and if you close the iex console the container will stop"
echo "[builder] WARNING2: the iex console is connected to your actual database"
echo "[builder]   Tread lightly"
echo "[builder] Once you exit the console the new build will be uploaded to s3"

exec /root/app/rel/$APP_NAME/bin/$APP_NAME console

