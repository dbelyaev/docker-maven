# DO NOT UPGRADE alpine until https://bugs.alpinelinux.org/issues/7372 is fixed
FROM openjdk:8u121-jdk-alpine

RUN apk add --no-cache curl tar bash

ARG MAVEN_VERSION=3.5.2
ARG USER_HOME_DIR="/root"
ARG SHA=707b1f6e390a65bde4af4cdaf2a24d45fc19a6ded00fff02e91626e3e42ceaff
ARG BASE_URL=https://apache.osuosl.org/maven/maven-3/${MAVEN_VERSION}/binaries

RUN mkdir -p /usr/share/maven /usr/share/maven/ref \
  && curl -fsSL -o /tmp/apache-maven.tar.gz ${BASE_URL}/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
  && echo "${SHA}  /tmp/apache-maven.tar.gz" | sha256sum -c - \
  && tar -xzf /tmp/apache-maven.tar.gz -C /usr/share/maven --strip-components=1 \
  && rm -f /tmp/apache-maven.tar.gz \
  && ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

# Git LFS
RUN apk add --no-cache git openssh \
    && curl -sLO https://github.com/github/git-lfs/releases/download/v2.3.4/git-lfs-linux-amd64-2.3.4.tar.gz \
    && tar zxvf git-lfs-linux-amd64-2.3.4.tar.gz \
    && mv git-lfs-2.3.4/git-lfs /usr/bin/ \
    && rm -rf git-lfs-2.3.4 \
    && rm -rf git-lfs-linux-amd64-2.3.4.tar.gz \
    && rm -rf /var/lib/apt/lists/*

ENV MAVEN_HOME /usr/share/maven
ENV MAVEN_CONFIG "$USER_HOME_DIR/.m2"

COPY mvn-entrypoint.sh /usr/local/bin/mvn-entrypoint.sh
COPY settings-docker.xml /usr/share/maven/ref/

# uncomment this section and add your own pom.xml in order to pre-package dependencies into image
#COPY pom.xml /tmp/pom.xml
#RUN mvn -B -f /tmp/pom.xml -s /usr/share/maven/ref/settings-docker.xml dependency:resolve
#RUN rm /tmp/pom.xml

# commented volume mounting as Bitbucket's Pipelines will start docker image using '--volume' argument in order
# to mount directory containing source from repository, completely replacing this volume mount point
# local repository entry was also updated in settings-docker.xml file to reflect this change
#VOLUME "$USER_HOME_DIR/.m2"

ENTRYPOINT ["/usr/local/bin/mvn-entrypoint.sh"]
CMD ["mvn"]
