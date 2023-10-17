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
    apache2 \
    apache2-suexec-custom \
    openssh-server \
    && apt-get clean

### configure ssh server
COPY --chown="0:0" --chmod="644" -- "./config/sshd_config.conf" "/etc/ssh/ssh_config.d/custom.conf"

### configure gitweb
COPY --chown="0:0" --chmod="644" -- "./config/gitweb.conf" "/etc/gitweb.conf"

## configure apache2
RUN rm -rf /etc/apache2/sites-enabled/000-default.conf
COPY --chown="0:0" --chmod="644" -- "./config/apache2.conf" "/etc/apache2/sites-available/000-gitweb.conf"
RUN ln -s "/etc/apache2/sites-available/000-gitweb.conf" "/etc/apache2/sites-enabled/000-gitweb.conf"
RUN a2enmod alias cgi suexec
COPY --chown="0:0" --chmod="644" -- "./config/suexex.conf" "/etc/apache2/suexec/git"

RUN sed -i 's/www-data/git/g' /etc/apache2/envvars
RUN sed -i 's/www-data/git/g' /etc/apache2/envvars

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


