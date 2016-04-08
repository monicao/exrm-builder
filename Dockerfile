# Alpine Linux 3.3
# Elixir 1.2.2
# Erlang 18.1
# Node.js 4.3.0
FROM msaraiva/elixir-dev:1.2.2

RUN apk update && \
    apk add nodejs && \
    apk add openssh-client && \
    apk add make && \
    apk add g++

# Install aws cli tools. Used to upload the build to S3.
RUN apk add python py-pip \
    && pip install --upgrade awscli \
    && apk del py-pip \
    && apk del py-setuptools \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

# Add github key to known hosts to avoid the git clone ssh prompt.
# Remove this line if you are strict about security.
# Autra's answer on SO has a good explanation for how this works:
# http://serverfault.com/questions/447028/non-interactive-git-clone-ssh-fingerprint-prompt
RUN mkdir -p /root/.ssh && \
    echo "github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==" >> /root/.ssh/known_hosts && \
    chmod 600 /root/.ssh/known_hosts

# main entry point. downloads source from master and compiles
COPY ./docker-entrypoint.sh /

ENTRYPOINT ["/docker-entrypoint.sh"]
