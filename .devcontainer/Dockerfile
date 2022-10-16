# syntax=docker/dockerfile:1
ARG NODE_IMAGE_TAG
FROM node:${NODE_IMAGE_TAG}

ARG GIT_VERSION=2.38.0
ARG PROJECT_NAME
ARG USER_NAME
ENV TZ=Asia/Tokyo

RUN <<-EOF
	set -e
	rm -f /etc/apt/apt.conf.d/docker-clean
	cat <<-'EOT' > /etc/apt/apt.conf.d/keep-cache
		Binary::apt::APT::Keep-Downloaded-Packages "true";
	EOT
EOF
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
		--mount=type=cache,target=/var/lib/apt,sharing=locked <<-EOF
	set -eu
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/\
	githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	apt-get purge -y git
	apt-get autoremove -y
	apt-get update -qq
	apt-get install -qy bash-completion \
											gettext \
											gh \
											libcurl4-gnutls-dev \
											libz-dev
	cd /usr/local/src
	wget https://github.com/git/git/archive/refs/tags/v${GIT_VERSION}.tar.gz
  tar -xzf v${GIT_VERSION}.tar.gz
  cd git-${GIT_VERSION}
  make prefix=/usr/local all -j "$(nproc)"
  make prefix=/usr/local install
EOF

RUN corepack enable npm

USER ${USER_NAME}
WORKDIR /${PROJECT_NAME}

RUN gh config set editor "code -w"

RUN <<-EOF
	set -eu
	cat <<-'EOT' >> /home/${USER_NAME}/.bashrc
		eval "$(gh completion -s bash)"
		if [ "$SHLVL" = 2 ]; then
		  script --flush ~/bashlog/script/`date "+%Y%m%d%H%M%S"`.log
		fi
		export PROMPT_COMMAND='history -a'
		export HISTFILE=~/bashlog/.bash_history
	EOT
	mkdir -p /home/${USER_NAME}/bashlog/script
	touch /home/${USER_NAME}/bashlog/.bash_history
EOF

RUN mkdir -p /home/${USER_NAME}/.vscode-server/extensions

EXPOSE 3000 9229

CMD ["yarn", "dev"]
