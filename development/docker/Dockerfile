FROM node:22.22.1

ARG RUBY_VERSION=2.6.1
ENV NPM_GLOBAL_PREFIX=/npm

WORKDIR /coco

ENV PATH $PATH:/root/.rbenv/bin:/root/.rbenv/shims
RUN apt-get update && \
    apt-get install -y git curl libssl-dev libreadline-dev zlib1g-dev autoconf bison \
                       build-essential libyaml-dev libncurses5-dev \
                       libffi-dev libgdbm-dev xvfb && \
    install -d -m 0755 /etc/apt/keyrings && \
    curl -fsSL https://packages.mozilla.org/apt/repo-signing-key.gpg -o /etc/apt/keyrings/packages.mozilla.org.asc && \
    gpg -n -q --import --import-options import-show /etc/apt/keyrings/packages.mozilla.org.asc | grep -q 35BAA0B33E9EB396F59CA838C0BA5CE6DC6315A3 && \
    echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" > /etc/apt/sources.list.d/mozilla.list && \
    printf 'Package: *\nPin: origin packages.mozilla.org\nPin-Priority: 1000\n' > /etc/apt/preferences.d/mozilla && \
    apt-get update && \
    apt-get install -y firefox && \
    rm -r /var/lib/apt/lists/* && \
    curl -sL https://github.com/rbenv/rbenv-installer/raw/main/bin/rbenv-installer | bash -

RUN rbenv install ${RUBY_VERSION} && \
    rbenv global ${RUBY_VERSION}

RUN mkdir $NPM_GLOBAL_PREFIX && \
    npm config set prefix $NPM_GLOBAL_PREFIX --global

COPY . .
