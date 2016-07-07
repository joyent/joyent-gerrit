#
# Dockerfile to build a Gerrit image.  At runtime, a volume container should be
# mounted at $GERRIT_HOME/review_site.  Its configuration will be clobbered by
# the configuration inside this image.
#

FROM java:jre-alpine

#
# Parameters related to fetching Gerrit, its plugins, and BouncyCastle.
#
ENV GERRIT_VERSION            2.12.2
ENV GERRIT_RELEASEURL         https://gerrit-releases.storage.googleapis.com

ENV PLUGIN_VERSION            stable-2.12
ENV GERRITFORGE_URL           https://gerrit-ci.gerritforge.com
ENV GERRITFORGE_ARTIFACT_DIR  lastSuccessfulBuild/artifact/buck-out/gen/plugins

ENV BOUNCY_CASTLE_VERSION     1.54
ENV BOUNCY_CASTLE_URL         http://central.maven.org/maven2/org/bouncycastle

#
# Parameters related to Gerrit's runtime behavior
#
ENV GERRIT_HOME               /var/gerrit
ENV GERRIT_SITE               ${GERRIT_HOME}/review_site
ENV GERRIT_WAR                ${GERRIT_HOME}/gerrit.war
ENV GERRIT_USER               gerrit2
ENV GERRIT_INIT_ARGS          ""

#
# We combine several of the following steps into a single "RUN" command because
# each separate command can be a little slow.  The steps are:
#
#    (1) Copy the start script and entry point into the container and make it
#        executable.
#
#    (2) Add the Gerrit user using the busybox "adduser" command as early as
#        possible to make sure it gets the expected uid.
#
#    (3) Install packages, both necessary (e.g., git, perl) and desirable (e.g.,
#        bash, vim, man).
#
#    (4) Fetch Gerrit itself and the JAR files for various plugins.
#
# We don't expose any ports from this image because it's deployed on Triton,
# where we use fabric-based networking.  Users can always expose these at
# runtime if desired.
#
COPY ./bin/gerrit-entrypoint.sh /
COPY ./bin/gerrit-start.sh      /
RUN  set -o xtrace && \
     chmod +x /gerrit-entrypoint.sh /gerrit-start.sh && \
     adduser -u 10000 -S -h "$GERRIT_HOME" $GERRIT_USER $GERRIT_USER && \
     apk add --update --no-cache bash curl git git-gitweb less \
         man openssh openssh-client openssl perl perl-cgi vim && \
     mkdir ${GERRIT_HOME}/shipped && \
     mkdir ${GERRIT_HOME}/shipped/plugins && \
     mkdir ${GERRIT_HOME}/shipped/lib && \
     wget -O $GERRIT_WAR \
         ${GERRIT_RELEASEURL}/gerrit-${GERRIT_VERSION}.war && \
     wget -O ${GERRIT_HOME}/shipped/plugins/delete-project.jar \
         ${GERRITFORGE_URL}/job/plugin-delete-project-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/delete-project/delete-project.jar && \
     wget -O ${GERRIT_HOME}/shipped/plugins/events-log.jar \
         ${GERRITFORGE_URL}/job/plugin-events-log-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/events-log/events-log.jar && \
     wget -O ${GERRIT_HOME}/shipped/plugins/gerrit-oauth-provider.jar \
         ${GERRITFORGE_URL}/job/plugin-gerrit-oauth-provider-gh-master/${GERRITFORGE_ARTIFACT_DIR}/gerrit-oauth-provider/gerrit-oauth-provider.jar && \
     wget -O ${GERRIT_HOME}/shipped/plugins/replication.jar \
         ${GERRITFORGE_URL}/job/plugin-replication-${PLUGIN_VERSION}/${GERRITFORGE_ARTIFACT_DIR}/replication/replication.jar && \
     wget -O ${GERRIT_HOME}/shipped/lib/bcprov-jdk15on-${BOUNCY_CASTLE_VERSION}.jar \
         ${BOUNCY_CASTLE_URL}/bcprov-jdk15on/${BOUNCY_CASTLE_VERSION}/bcprov-jdk15on-${BOUNCY_CASTLE_VERSION}.jar && \
     wget -O ${GERRIT_HOME}/shipped/lib/bcpkix-jdk15on-${BOUNCY_CASTLE_VERSION}.jar \
         ${BOUNCY_CASTLE_URL}/bcpkix-jdk15on/${BOUNCY_CASTLE_VERSION}/bcpkix-jdk15on-${BOUNCY_CASTLE_VERSION}.jar && \
     chown -R ${GERRIT_USER} ${GERRIT_WAR} ${GERRIT_HOME}/shipped

#
# Copy our site-specific configuration into the image.
#
COPY ./etc/gerrit.config.base ${GERRIT_HOME}/shipped/gerrit.config.base
COPY ./etc/replication.config ${GERRIT_HOME}/shipped/replication.config

#
# Configure the entrypoint (which runs every time) and the default start
# command.
#
ENTRYPOINT [ "/gerrit-entrypoint.sh" ]
CMD        [ "/gerrit-start.sh" ]
