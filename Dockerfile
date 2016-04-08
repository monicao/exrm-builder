# Alpine Linux 3.3
# Elixir 1.2.2
# Erlang 18.1
# Node.js 4.3.0
FROM msaraiva/elixir-dev:1.2.2

RUN apk update; apk add nodejs

# Install aws cli tools. Used to upload the build to S3.
RUN apk add python py-pip \
    && pip install --upgrade awscli \
    && apk del py-pip \
    && apk del py-setuptools \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Credentials for the S3 bucket that will hold the release
COPY ./aws/credentials /root/.aws/credentials

#
# Configure git info so exrm can pull source code from git
#

# Copy the deploy keys over so root can clone the repo
RUN mkdir /root/.ssh
COPY ./ssh/id_rsa.pub /root/.ssh/id_rsa.pub
COPY ./ssh/id_rsa /root/.ssh/id_rsa

# Fix .ssh permissions
#
# Add github key to known hosts to avoid the git clone ssh prompt.
# Remove this line if you are strict about security.
# Autra's answer on SO has a good explanation for how this works:
# http://serverfault.com/questions/447028/non-interactive-git-clone-ssh-fingerprint-prompt
RUN chmod 700 /root/.ssh && \
    chmod 600 /root/.ssh/id_rsa && \
    chmod 655 /root/.ssh/id_rsa.pub && \
    echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /root/.ssh/known_hosts

# main entry point. downloads source from master and compiles
COPY ./docker-entrypoint.sh /

# mix task runner
COPY ./run-task.sh /

# creates a new build and uploads it to the production server
COPY ./build-release.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
