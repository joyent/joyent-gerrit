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
