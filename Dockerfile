FROM node:20.0.0

ARG PROJECT_NAME
ARG USER_NAME
ENV TZ=Asia/Tokyo

RUN corepack enable npm yarn

USER ${USER_NAME}

WORKDIR /home/${USER_NAME}/${PROJECT_NAME}

EXPOSE 3000 6006 9230

CMD ["bash", "-c", "node --inspect=0.0.0.0 -r ./.pnp.cjs $(yarn bin next) dev"]
