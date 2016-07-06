# cr.joyent.us operator guide

This document needs a lot of work!

## Setting up new users

Because cr.joyent.us is on the internet and uses GitHub for authentication,
anybody can register an account and start using it.  That's by design, so that
we can code review and accept community contributions. However, only authorized
users will be able to approve changes.

New users that are employees of Joyent should be added to the Gerrit group
called ["Joyent Team"](https://cr.joyent.us/#/admin/groups/6).

New users that are not employees of Joyent, but which we will trust for
approvals should be put into a new group called "External Approvers".  (This
hasn't happened yet.)  That group should in turn become a member of "Change
Approver Role".

**Background:** we're keeping Joyent Team and External Approvers as separate
groups, but both ultimately need to be part of "Change Approver Role", so that's
why there are separate groups.


## Deployment notes

This section needs work.

### Environment

us-west-1 (behind TLS), using CNS for internal and external service discovery.

### Topology

Gerrit uses both a PostgreSQL database and the local filesystem.  In order to
ensure that we can redeploy PostgreSQL and Gerrit itself without losing data, we
use separate data volumes for the PostgreSQL database and for the local
filesystem.

There are five total containers:

- data container for the PostgreSQL database
- data container for Gerrits local filesystem data
- PostgreSQL database
- Gerrit itself
- nginx proxy (the only thing that's public)

The data containers never need to be modified or redeployed.  The PostgreSQL,
Gerrit, and nginx containers can be redeployed as desired to update
configuration or upgrade software, subject to the same constraints around
compatibility of on-disk formats as PostgreSQL and Gerrit normally have with
local filesystem storage.

### Service discovery

We've created a CNAME in public DNS for `cr.joyent.us`.  This points to a
CNS-provided DNS name for the gerrit service.  This way, if we want to redeploy
the Gerrit instance, the instance IP may change, but the CNS name will be
automatically updated with the new IP address, so users of the public CNAME will
also get the new IP.  (It's not clear that Gerrit supports multiple instances
running on the same data, so rolling upgrades are likely not possible, but this
approach still makes it easy to upgrade instances.)

### Build steps

We have custom images for the Gerrit application server and for the nginx proxy.
These will be moved into this repository.

### Backup/restore

There are some janky backup/restore scripts that will be moved into this
repository.  These need some work.

Backup effectively works by shutting down the appserver container, using
`pg_dump` to backup the database, and using `docker cp` to create a tarball of
the Gerrit data volume.  Restore builds up the entire stack from scratch,
restoring these two chunks of data using `pg_restore` and `docker cp`.

### GitHub auth

To use GitHub auth, we've set up a [GitHub
application](https://github.com/organizations/joyent/settings/applications/371013).
If the public hostname changes, this needs to be updated.

### Manual deployment steps

**Note: the best way to deploy a new stand-up is using the gerritrestore script
on an existing backup.  These instructions may grow out of date!**

These instructions won't work as-is for non-Joyent\_Dev deployments.

PostgreSQL data container:

    # docker run --name=gerrit-volume-db -v /gerrit-postgres-db-data ubuntu echo "Database volume container created."

Gerrit data container:

    # docker run --name=gerrit-volume-gerrit -v /var/gerrit/review_site ubuntu echo "Gerrit volume container created."

PostgreSQL runtime container:

    # docker run \
        --name gerrit-postgres \
	--label triton.cns.services=gerritdb \
        -e POSTGRES_USER=gerrit2 \
        -e POSTGRES_PASSWORD=gerrit \
        -e POSTGRES_DB=reviewdb \
        -e PGDATA=/gerrit-postgres-db-data \
        --volumes-from gerrit-volume-db \
        --restart=always \
        -d postgres:9.5.3

Note: this doesn't use -p to expose the port because it will be on a Triton
fabric network.  In an environment without fabrics set up, you may need "-p
5432:5432".

Gerrit app container:

    # docker run \
        --name gerrit-appserver \
        --label triton.cns.services=gerrit \
        --volumes-from=gerrit-volume-gerrit \
        --restart=always \
        -e AUTH_TYPE=OAUTH \
        -e OAUTH_GITHUB_CLIENT_ID=... \
        -e OAUTH_GITHUB_CLIENT_SECRET=... \
        -e DATABASE_TYPE=postgresql \
        -e DB_PORT_5432_TCP_ADDR=gerritdb.svc.ddb63097-4093-4a74-b8e8-56b23eb253e0.us-west-1.cns.joyent.com \
        -e WEBURL=http://cr.joyent.us \
        -e SMTP_SERVER=relay.joyent.com \
        -e SMTP_CONNECT_TIMEOUT=60sec \
        -e USER_EMAIL=no-reply@cr.joyent.us \
        -d joyent/joyent-gerrit:dev

Note: this also assumes fabrics with Docker containers.  Without it, you'll want
to add `--link gerrit-postgres:db -p 8080:8080 -p 29418:29418` and remove the
database flags other than DATABASE\_TYPE.

Front door container:

    docker run -d \
        --name=gerrit-frontdoor \
        --label triton.cns.services=gerrit \
        -e MY_NAME=cr.joyent.us \
        -e GERRIT_HOST=gerrit-backend.svc.JOYENT_DEV_ACCOUNT_ID.us-west-1.cns.joyent.com \
        -e SSH_PORT=29418 \
        -e HTTP_PORT=8080 \
        -p 22 \
        -p 80 \
        -p 443 \
        -p 29418 \
        arekinath/gerrit-nginx

## Setup notes

* Mail notifications: see SMTP and USER\_EMAIL params in deployment
* GitHub auth: see AUTH/OATH params in deployment
* Auto-links in commit comments to issue trackers
  * add two sections to /var/gerrit/review\_site/etc/gerrit.config
  * had originally created a separate Docker image with a customization script
    to do this, but the actual files were stored on the data volume anyway,
    so there's no point in putting the initialization into the app server image.
* Replication to GitHub
  * Created /var/gerrit/.ssh/known\_hosts with GitHub host key.
  * Created SSH key pair in /var/gerrit/.ssh/id\_rsa and added the public key
    to the GitHub "joyent-automation" account.
  * Created Gerrit auth group "GitHub (joyent) Replication Group".
  * Created project under All-Projects for projects that should be replicated
    to GitHub/Joyent.
  * Created /var/gerrit/review\_site/etc/replication.config.
  * Went back to custom image in order to install replication.jar.
* Migration to west-1
  * Enabled CNS for "Joyent\_Dev" account.
  * Updated gerritrestore.sh script to add nginx container and update params for
    appserver container.
  * Updated relay.joyent.com access.
  * Updated gerrit.config advertisedAddress.
* Enable GitWeb for public access: added READ access to refs/meta/config on
  All-Projects.
* Enable pushing merge commits for administrators to All-Projects so that we can
  import projects from GitHub that have merge commits already.

## References

* https://github.com/openfrontier/docker-gerrit
* https://gerrit.googlesource.com/plugins/github/+/master/README.md
* https://www.packtpub.com/books/content/using-gerrit-github
* https://hub.docker.com/\_/postgres/
* Replication: https://gist.github.com/Aricg/56f1a769cbdcbb93b459

## Known issues

Importing platform: could not push existing platform repo to Gerrit ssh server
because of invalid commit messages.  Instead, used "docker exec", cloned repo
from GitHub, and pushed to local copy.

Attempted to create node-cueball project, but it actually created a new change
for each commit.  I haven't seen this again, so I don't know what caused it.

By attempting to remove an old version of the node-cueball project, that project
wound up in a busted state.  I can't access changes for it, and I can't delete
it.  Reports a ConcurrentModificationException.  This was in a previous
deployment; it's no longer present in the current deployment.

Issues from migration from staging to west1:

* Official Triton docs don't work for setting up my Docker client cert.
  I used my existing one, but that ended up creating stuff under the wrong
  user (dap instead of Joyent\_Dev).
* PostgreSQL docs are confusing/wrong about how to restore a DB.  Need to use
  the command documented separately.
* openfrontier image changed to a version with no bash, which broke my customize
  script.
* Networking params and CNS names are different in JPC than staging.
* Some provision failures in west-1.
