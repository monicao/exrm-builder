## exrm docker image

Based on [msaraiva/elixir-dev](https://hub.docker.com/r/msaraiva/elixir-dev/) (Alpine linux 3.3, x86_64)

This image builds a phoenix project, creates a release and uploads the release to S3. (It probably works with other elixir apps, but this README provides instructions for phoenix specifically.)

Once you have a release in S3, you simply download the release to your production server and run the application on the erlang vm.

This docker image solves two problems:

- Your development machine has a different architecture than your production machine. Elixir releases need to be built on the same architecture that they will run on. (http://www.phoenixframework.org/docs/advanced-deployment#section-what-we-ll-need). This docker container uses 64-bit linux.

- You want to automate your deployment with docker

A side benefit of storing releases in S3 is that it is easier to roll back to an older version.

### Setup


#### S3 Bucket

Create an S3 bucket that will contain the .tar.gz of the phoenix release.

Create a file that stores your S3 credentials so the container can upload the build to the bucket (using the aws cli tool). The file should be called `credentials`

```
[default]
aws_access_key_id = <release-bucket-access-key-id>
aws_secret_access_key = <release-bucket-secret-access-key>
```

#### SSH Keys for deployment

Obtain ssh keys for the git repo that contains your phoenix app. The container will use these ssh keys to clone the code. For better security, consider using [read-only deploy keys](https://github.com/blog/2024-read-only-deploy-keys).

#### Production Config

Before deploying make sure your production settings are correct. Edit your phoenix application's config/prod.exs to ensure you have the correct port, app secret and database connection information.

Set the version in the `mix.exs` file.

```elixir
  def project do
    [app: :my_app,
     description: "My sample app.",
     version: "0.0.4",   # <--- set your version here
     elixir: "~> 1.1",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases,
     deps: deps]
  end
```

Add exrm as a dependency in `mix.exs`.

```elixir
  defp deps do
    [{:phoenix, "~> 1.1.4"},
     {:phoenix_ecto, "~> 2.0.1"},
     {:postgrex, ">= 0.11.1"},
     {:phoenix_html, "~> 2.1"},
     {:phoenix_live_reload, "~> 1.0.3", only: :dev},
     {:exrm, "~> 1.0.3"}
    ]
  end
```

### Creating a release

Commit your changes and tag the release. The builder will use this tag to clone the release.

```
git commit -am "Configure app for deployment"
git push origin master
git tag -a 0.0.1
git push origin --tags
```

Run the command below to start the build container that will create the release and upload it to S3. 

Use the `-v` switches to provide the container with the deployment keys and the credentials for the S3 bucket (see Setup above).

Use the `-e` switches to set up environment variables that your app needs during the build phase. The builder needs the `S3_BUCKET`, `VERSION` and `REPO_URL`.

You also need to include any environment variables you used in your `config/prod.exs` file. For example your `config/prod.exs` could use `System.get_env('SECRET_KEY_BASE')` to avoid committing your secret key to the repo. In that case you must specify the SECRET_KEY_BASE as an environment variable below so it is available to the container when it builds the app.

```
docker run \
    --name builder \
    -v /your/path/to/private/key:/root/.ssh/id_rsa:ro \
    -v /your/path/to/public/key:/root/.ssh/id_rsa.pub:ro \
    -v /your/path/to/s3/credentials:/root/.aws/credentials:ro \
    -e S3_BUCKET="your-release-bucket" \
    -e VERSION="0.0.1" \
    -e REPO_URL="git@github.com:you/yourapp.git" \
    -e SECRET_KEY_BASE=supersecret \
    -it --rm mochromatic/exrm-builder
```

```
[builder] Building some awesomeness. Fasten your seatbelt.
Cloning into '/root/app'...
Warning: Permanently added the RSA host key for IP address '192.30.252.120' to the list of known hosts.
remote: Counting objects: 805, done.
...
[builder] Done! Your application has been uploaded to s3://your-release-bucket.s3.amazonaws.com/releases/appname-0.0.1.tar.gz
[builder] Starting iex console to test that the app will boot
[builder] WARNING: if your app has a database this console is connected
[builder]   to the database. Tread lightly
Using /root/app/rel/appname/releases/0.0.1/appname.sh
created directory: '/root/app/rel/appname/running-config'
Exec: /root/app/rel/appname/erts-7.1/bin/erlexec -boot /root/app/rel/appname/releases/0.0.1/appname -mode embedded -config /root/app/rel/appname/running-config/sys.config -boot_var ERTS_LIB_DIR /root/app/rel/appname/erts-7.1/../lib -env ERL_LIBS /root/app/rel/appname/lib -pa /root/app/rel/appname/lib/appname-0.0.1/consolidated -args_file /root/app/rel/appname/running-config/vm.args -user Elixir.IEx.CLI -extra --no-halt +iex -- console
Root: /root/app/rel/appname
/root/app/rel/appname
Erlang/OTP 18 [erts-7.1] [source] [64-bit] [async-threads:10] [kernel-poll:false]

2016-04-08 07:57:22.216 [info] Running Appname.Endpoint with Cowboy using http on port 4000
Interactive Elixir (1.2.2) - press Ctrl+C to exit (type h() ENTER for help)
iex(appname@1a7a0ea4f331)1>

```

You should see a `releases/app_name-version.tar.gz` file in your S3 bucket.

The builder starts the console at the end of the build process to ensure that the release boots up. Exit the console with Ctrl-C. The docker container will remove itself.

### Troubleshooting

#### System error: not a directory

This docker error usually happens if one of the volumes you specified could not be mounted. This could happen if the path in the `-v` flag is incorrect.

#### The user-provided path /root/app/rel/yourapp/releases/0.0.1/yourapp.tar.gz does not exist.

Make sure your version in mix.exs corresponds to the version you set with the `-e` flag.


#### I want to see each command in the build process

You can run the container with the DEBUG=1 flag to turn on `set -x` which displays all shell commands that are being run. That can give you a better idea of which build step failed.

### Running mix tasks

This is out of scope for the building phase, but it is worth mentioning here because any app that uses a database will need to run `mix ecto.migrate` during the deployment phase.

Exrm does not package mix tasks during the build process. This [github issue](https://github.com/bitwalker/exrm/issues/67) discusses different ways you can get mix tasks to work. @jwarlander's approach worked for me.

### References

- http://www.phoenixframework.org/docs/advanced-deployment
- https://medium.com/@diamondgfx/deploying-phoenix-applications-with-exrm-97a3867ebd04#.hwapy3qs4


