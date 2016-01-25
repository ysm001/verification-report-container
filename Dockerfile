FROM centos:centos6

# install dev tools
RUN yum -y install gcc gcc-c++ git rsync tar openssl openssl-devel readline-devel  zlib-devel libffi-devel gdbm-devel tk tk-devel tcl tcl-devel patch gcc-c++ which sqlite-devel wget openssh-server bzip2

# install ruby
RUN git clone https://github.com/sstephenson/rbenv.git /root/.rbenv
RUN git clone https://github.com/sstephenson/ruby-build.git /root/.rbenv/plugins/ruby-build
RUN ./root/.rbenv/plugins/ruby-build/install.sh
ENV PATH /root/.rbenv/bin:$PATH
RUN echo 'export PATH=/root/.rbenv/bin:$PATH' >> /root/.bashrc
RUN echo 'eval "$(rbenv init -)"' >> /root/.bashrc

# set ruby version to 2.2.2
ENV CONFIGURE_OPTS --disable-install-doc
RUN rbenv install 2.2.2 && rbenv global 2.2.2

# Install nvm with node and npm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 4.1.0

RUN wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.30.1/install.sh | bash \
      && source $NVM_DIR/nvm.sh \
      && nvm install $NODE_VERSION \
      && nvm alias default $NODE_VERSION \
      && nvm use default

ENV NODE_PATH $NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# install npm, bower
RUN yum -y install epel-release && yum -y install npm --enablerepo=epel
RUN npm install -g bower

# install mongodb
COPY mongodb.repo /etc/yum.repos.d/mongodb.repo
RUN yum install -y -v mongodb-org

# install supervisor
RUN curl -kL https://raw.github.com/pypa/pip/master/contrib/get-pip.py | python
RUN pip install supervisor

# set directories path to env
ENV WORKDIR=/workspace
ENV FRONTDIR=$WORKDIR/vr-frontend BACKDIR=$WORKDIR/vr-backend DBDIR=/data/db CACHEDIR=$WORKDIR/vr-cache-server LOGDIR=/var/log

# move to working directory
WORKDIR $WORKDIR

# add dummy file to avoid caching
ADD dummyfile /data/

# clone Verification Report Frontend to $FRONTDIR and install
RUN git clone https://github.com/ysm001/verification-report.git $FRONTDIR
WORKDIR $FRONTDIR
RUN npm install && bower install --allow-root

# clone Verification Report Backend to $BACKDIR and install
RUN git clone https://github.com/ysm001/bench-parsers.git $BACKDIR
WORKDIR $BACKDIR
RUN npm install

# clone Verification Report CacheServer to $CACHEDIR and install
RUN git clone https://github.com/ysm001/verification-report-cache-server.git $CACHEDIR
WORKDIR $CACHEDIR
RUN npm install

# configure supervisord
RUN mkdir -p $LOGDIR && mkdir -p $DBDIR
COPY supervisord.conf /etc/supervisord.conf
RUN sed -i -e "s@\$FRONTDIR@$FRONTDIR@g" /etc/supervisord.conf \
      && sed -i -e "s@\$BACKDIR@$BACKDIR@g" /etc/supervisord.conf \
      && sed -i -e "s@\$LOGDIR@$LOGDIR@g" /etc/supervisord.conf \
      && sed -i -e "s@\$DBDIR@$DBDIR@g" /etc/supervisord.conf \
      && sed -i -e "s@\$CACHEDIR@$CACHEDIR@g" /etc/supervisord.conf

# move to working directory
WORKDIR $FRONTDIR
RUN npm rebuild node-sass

EXPOSE 3000 9001
CMD /usr/bin/supervisord -c /etc/supervisord.conf
