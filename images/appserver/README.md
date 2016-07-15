# Docker image for Gerrit

This Docker image is heavily inspired by the OpenFrontier image at
https://github.com/openfrontier/docker-gerrit.

That image is a good choice for getting started with Gerrit using Docker.

Important notes about this image:

* This image uses an external data volume for the actual site directory so that
  it's easy to redeploy without losing data.  As a result, this doesn't support
  initial setup -- it assumes you're going to mount a data directory in the
  appropriate place.
* That said, this image is intended to be deployed using the `crrestore` script
  inside this repository, which deploys the entire application from a backup.
  That script always deploys a new volume container, restores the contents from
  the backup, and then deploys this image attached to that container.
* Due to [DOCKER-774](https://smartos.org/bugview/DOCKER-774), this image cannot
  currently be built on Triton.
* To work around [TOOLS-1486](https://devhub.joyent.com/jira/browse/TOOLS-1486),
  this image currently uses a custom Joyent-specific build of Gerrit, rather
  than a stock release build.  More detail appears below in the
  [Gerrit Releases and Custom Builds](#gerrit-releases-and-custom-builds)
  section.


## Gerrit configuration

This image is intended to be deployed not just for cr.joyent.us, but for staging
and development versions.  As such, we divide configuration into three groups:

- basic Gerrit configuration that is common to all deployments (i.e.,
  preferences, policies, and the like)
- shared secrets (e.g., private keys used to push to GitHub)
- deployment-specific configuration (e.g., hostnames of external dependencies,
  advertised addresses, and the like).

The basic configuration is checked into this repository and built into this
image so that it can be versioned the way software is.  In principle, we could
use blue-green deployments for configuration changes, though Gerrit doesn't
really support that model.

Shared secrets are stored inside the volume directory.  This allows the
repository itself to be made public (including the deployment tooling, which
would need to specify these shared secrets if they were supplied as environment
variables).

Deployment-specific configuration is specified via environment variables when
the container is deployed.

The following runtime parameters are provided to specify deployment-specific
configuration.  **These are automatically specified by the crrestore script.**
You generally don't need to specify these unless you're doing dev work on the
image or tools themselves.

* `JG_DATABASE_HOSTNAME` (required): Maps directly to `database.hostname`.
* `JG_CANONICALWEBURL` (required): Maps directly to `gerrit.canonicalWebUrl`.
* `JG_SENDEMAIL_SMTPSERVER`: Maps directly to `sendemail.smtpServer`.
* `JG_SSHD_ADVERTISEDADDRESS`: Maps directly to `sshd.advertisedAddress`.
* `JG_HTTPD_LISTENURL`: Maps directly to `httpd.listenUrl`.
* `JG_USER_EMAIL`: Maps directly to `user.email`.
* `JG_GITHUB_CLIENT_ID`: Maps directly to
  `plugin.gerrit-oauth-provider-github-oauth.client-id`.
* `JG_GITHUB_CLIENT_SECRET`: Maps directly to
  `plugin.gerrit-oauth-provider-github-oauth.client-secret`.
* `JG_JOYENT_ENABLE_REPLICATION`: If specified, this causes the
  `replication.config` file to be linked into place to enable replication to
  GitHub.  If unspecified, this file will be present in the image, but not
  linked in a way that Gerrit will use it.

As mentioned above, configuration that is not deployment-specific is
deliberately not supported through environment variables.  You have to modify
the config in this repository, build a new image, and redeploy that in order to
change that.

## Gerrit Releases and Custom Builds

Gerrit releases are generally made available through [the Gerrit web site]
(https://www.gerritcodereview.com/).  The `Dockerfile` uses an internal
environment variable, `GERRIT_WAR_URL`, to prescribe the location from which the
`gerrit.war` artefact will be obtained.  Ordinarily, this will point at a stock
binary release from the Gerrit project itself.  At times, the URL may be
overridden to a Joyent-specific build that includes fixes that have not yet
been made available in a full public release.

There is a Joyent fork of Gerrit available in the Github repository
[joyent/gerrit](https://github.com/joyent/gerrit).  At the time of writing,
this repository included a `joyent-2.12.2` branch with the fix for
[an authentication issue primarily seen when using multiple tabs]
(https://gerrit-review.googlesource.com/#/c/74830/2).  A `v2.12.2-joyent1`
tag was created, from which the [Gerrit Release WAR file]
(https://gerrit-documentation.storage.googleapis.com/Documentation/2.12.3/dev-buck.html#release)
build instructions were followed to produce a WAR file then stored in Manta.

By altering the `GERRIT_WAR_URL` in the `Dockerfile`, either this custom build,
or any other Gerrit WAR file, can be included in place of the stock release.
Note that when changing from one version to another, it is important to ensure
that any included plugins (obtained via `GERRITFORGE_URL` or similar) match the
custom WAR file in use.
