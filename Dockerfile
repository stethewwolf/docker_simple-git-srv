FROM debian:stable-slim
LABEL maintainer=stethewwolf@posteo.net

## declare exposed ports
# http port
EXPOSE	80
# ssh port
EXPOSE	22

## configure the system
### install system requirements packages

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    git \
    gitolite3 \
    gitweb \
    nginx \
    fcgiwrap \
    spawn-fcgi \
    openssh-server \
    apache2-utils \
    && apt-get clean

### configure ssh server
COPY --chown="0:0" --chmod="644" -- "./config/sshd_config.conf" "/etc/ssh/ssh_config.d/custom.conf"

### configure gitweb
COPY --chown="0:0" --chmod="644" -- "./config/gitweb.conf" "/etc/gitweb.conf"

## configure nginx
RUN sed -i 's/www-data/git/g' /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/sites-enabled/default
COPY --chown="0:0" --chmod="644" -- "./config/nginx.conf" "/etc/nginx/sites-available/gitweb.conf"
RUN ln -s "/etc/nginx/sites-available/gitweb.conf" "/etc/nginx/sites-enabled/gitweb.conf"

### copy scripts 
ADD --chown="0:0" --chmod="755" -- "./scripts" "/usr/local/bin"

### create the git user 
ARG GIT_USER="git"
ARG GIT_ADMIN="gitolite"
ARG GIT_HOME_DIR="/var/lib/$GIT_USER/"
ARG GIT_REPO_DIR="$GIT_HOME_DIR/repositories"
ARG GIT_BIN_DIR="$GIT_HOME_DIR/bin"
ARG GIT_WEB_ROOT="/usr/share/gitweb"
ARG GIT_LOG_DIR="$GIT_HOME_DIR/log"
ARG GIT_TMP_DIR="$GIT_HOME_DIR/tmp"

RUN echo "" >> /etc/environment
RUN echo "export GIT_USER=$GIT_USER" >> /etc/environment
RUN echo "export GIT_ADMIN=$GIT_ADMIN" >> /etc/environment
RUN echo "export GIT_HOME_DIR=$GIT_HOME_DIR" >> /etc/environment
RUN echo "export GIT_WEB_ROOT=$GIT_WEB_ROOT" >> /etc/environment
RUN echo "export GIT_LOG_DIR=$GIT_LOG_DIR" >> /etc/environment
RUN echo "export GIT_BIN_DIR=$GIT_BIN_DIR" >> /etc/environment
RUN echo "export GIT_TMP_DIR=$GIT_TMP_DIR" >> /etc/environment

RUN groupadd --system ssh
RUN useradd --create-home --home-dir $GIT_HOME_DIR --system --user-group --groups ssh $GIT_USER
RUN chown -R $GIT_USER: $GIT_HOME_DIR

RUN echo "/etc/environment" >> $GIT_HOME_DIR/.bashrc
RUN echo 'export PATH=$GIT_BIN_DIR:$PATH' >> $GIT_HOME_DIR/.bashrc

# Entrypoint, how container is run
# use root user
USER root
WORKDIR /

ENTRYPOINT ["entrypoint.sh"]

CMD [ "/usr/bin/sleep", "infinity" ]


