# syntax=docker/dockerfile:1
ARG NODE_IMAGE_TAG
FROM node:${NODE_IMAGE_TAG}

ARG PROJECT_NAME
ARG USER_NAME
ENV TZ=Asia/Tokyo

RUN <<-EOF
	set -e
	curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
	| dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
	chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
	echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/\
	githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
	| tee /etc/apt/sources.list.d/github-cli.list > /dev/null
	apt-get update -qq
	apt-get install -qy bash-completion gh
EOF

RUN corepack enable npm

USER ${USER_NAME}
WORKDIR /${PROJECT_NAME}

RUN gh config set editor "code -w"

RUN <<-EOF
	set -eu
	cat <<-'EOT' >> /home/${USER_NAME}/.bashrc
		eval "$(gh completion -s bash)"
		if [ "$SHLVL" = 2 ] ; then
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
