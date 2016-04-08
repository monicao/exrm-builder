## exrm docker image

This image builds a phoenix project, creates a release and uploads the release to S3.

From there, you can just download the release to your production server and run the application on the erlang vm.

### Setup

Create an S3 bucket that will contain the .tar.gz of the phoenix release.

### Usage

Before deploying make sure your production settings are correct. Edit your phoenix application's config/prod.exs to ensure you have the correct port, app secret and database connection information.

Update your application version in the `mix.exs` file.

```
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

Then commit your changes and create a tag for the release.

```
git commit -am "Bumping version to 0.0.4"
git push origin master
git tag -a 0.0.4
git push origin --tags
```

The builder will use this tag to clone the release.

Run the command below to build the release.

```
docker run \
    --name builder \
    -v ~/.ssh/id_rsa:/root/.ssh/id_rsa \
    -v ~/.ssh/id_rsa.pub:/root/.ssh/id_rsa.pub \
    -v ~/.aws/credentials:/root/.aws/credentials \
    -e S3_BUCKET="your-release-bucket" \
    -e VERSION="0.0.4" \
    -e REPO_URL="git@github.com:you/yourapp.git" \
    -e PORT=4000 \
    -it --rm exrm-builder
```