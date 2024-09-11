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
    bash \
    git \
    gitolite3 \
    gitweb \
    nginx \
    fcgiwrap \
    spawn-fcgi \
    openssh-server \
    apache2-utils \
    locales \
    python3-git \
    python3-yaml \
    python3 \
    python3-pip \
    cron \
    sudo \
    build-essential \
    python3-dev \
    libssl-dev \
    libffi-dev \
    && apt-get clean

RUN pip3 install --break-system-packages 'buildbot[bundle]'

COPY "./init.d/buildbot" "/etc/init.d/buildbot"
RUN chmod 755 "/etc/init.d/buildbot"

### configure locales
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

### configure ssh server
COPY "./config/sshd_config.conf" "/etc/ssh/sshd_config.d/custom.conf"
RUN chown root:root /etc/ssh/sshd_config.d/custom.conf
RUN chmod 644 /etc/ssh/sshd_config.d/custom.conf

### configure gitweb
COPY "./config/gitweb.conf" "/etc/gitweb.conf"
RUN chmod 644 "/etc/gitweb.conf"
RUN chown root:root "/etc/gitweb.conf"

## configure nginx
RUN sed -i 's/www-data/git/g' /etc/nginx/nginx.conf
RUN rm -rf /etc/nginx/sites-enabled/default
COPY "./config/nginx.conf" "/etc/nginx/sites-available/gitweb.conf"
RUN chmod 644 "/etc/nginx/sites-available/gitweb.conf"
RUN chown root:root "/etc/nginx/sites-available/gitweb.conf"
RUN ln -s "/etc/nginx/sites-available/gitweb.conf" "/etc/nginx/sites-enabled/gitweb.conf"

### copy scripts 
ADD "./scripts" "/usr/local/bin"
RUN chown -R root:root "/usr/local/bin"
RUN chmod -R 755 "/usr/local/bin/"

### create the git user 
ARG GIT_USER="git"
ARG GIT_USER_ID="888"
ARG GIT_ADMIN="gitolite"
ARG GIT_HOME_DIR="/var/lib/$GIT_USER/"
ARG GIT_REPO_DIR="$GIT_HOME_DIR/repositories"
ARG GIT_BIN_DIR="$GIT_HOME_DIR/bin"
ARG GIT_WEB_ROOT="/usr/share/gitweb"
ARG GIT_LOG_DIR="$GIT_HOME_DIR/log"
ARG GIT_TMP_DIR="$GIT_HOME_DIR/tmp"
ARG BUILDBOT_USER_ID="887"
ARG BUILDBOT_USER="buildbot"
ARG BUILDBOT_HOME_DIR="/var/lib/$BUILDBOT_USER/"

# define env varialbes
RUN echo "" >> /etc/environment
RUN echo "export GIT_USER=$GIT_USER" >> /etc/environment
RUN echo "export GIT_ADMIN=$GIT_ADMIN" >> /etc/environment
RUN echo "export GIT_HOME_DIR=$GIT_HOME_DIR" >> /etc/environment
RUN echo "export GIT_WEB_ROOT=$GIT_WEB_ROOT" >> /etc/environment
RUN echo "export GIT_LOG_DIR=$GIT_LOG_DIR" >> /etc/environment
RUN echo "export GIT_BIN_DIR=$GIT_BIN_DIR" >> /etc/environment
RUN echo "export GIT_TMP_DIR=$GIT_TMP_DIR" >> /etc/environment
Run echo "export LANGUAGE=en_US.UTF-8" >> /etc/environment
Run echo "export LC_ALL=en_US.UTF-8" >> /etc/environment
Run echo "export LANG=en_US.UTF-8" >> /etc/environment
Run echo "export LC_CTYPE=en_US.UTF-8" >> /etc/environment
Run echo "export BUILDBOT_USER=$BUILDBOT_USER" >> /etc/environment
Run echo "export BUILDBOT_HOME_DIR=$BUILDBOT_HOME_DIR" >> /etc/environment

# create and cofigure buildbot user
RUN useradd --create-home --home-dir $BUILDBOT_HOME_DIR --system --user-group --uid $BUILDBOT_USER_ID $BUILDBOT_USER

# create and cofigure git user
RUN groupadd --system ssh
RUN useradd --create-home --home-dir $GIT_HOME_DIR --system --user-group --uid $GIT_USER_ID --groups $BUILDBOT_USER,ssh $GIT_USER
RUN chown -R $GIT_USER: $GIT_HOME_DIR
COPY "./config/sudo" "/etc/sudoers.d/gitolite"

RUN echo ". /etc/environment" >> $GIT_HOME_DIR/.bashrc
RUN echo 'export PATH=$GIT_BIN_DIR:$PATH' >> $GIT_HOME_DIR/.bashrc

# override buildbot conf in /etc/default folder
COPY config/etc_default_buildbot /etc/default/buildbot
RUN /usr/local/bin/buildbot create-master /var/lib/buildbot
RUN rm /var/lib/buildbot/master.cfg.sample
COPY config/master.cfg /var/lib/buildbot/master.cfg
RUN chown -R buildbot: /var/lib/buildbot/
RUN chmod 775 /var/lib/buildbot/
RUN chmod 664 /var/lib/buildbot/master.cfg

# add crontab for gitolite-mirror
COPY config/crontab /etc/cron.d/gitolite

# Entrypoint, how container is run
# use root user
USER root
WORKDIR /

# define entrypoint
ENTRYPOINT ["entrypoint.sh"]

# run sleep infinity
CMD [ "/usr/bin/sleep", "infinity" ]

