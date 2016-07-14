<!--
    This Source Code Form is subject to the terms of the Mozilla Public
    License, v. 2.0. If a copy of the MPL was not distributed with this
    file, You can obtain one at http://mozilla.org/MPL/2.0/.
-->

<!--
    Copyright 2016 Joyent, Inc.
-->

# cr.joyent.us operator guide

This document needs a lot of work!

## Site policy and configuration

### Access Control (Groups)

Gerrit supports access control through Groups.

Most privileges in Gerrit are configured at the Project level, and on
cr.joyent.us, nearly all of those privileges are inherited from the top-level
"All-Projects" project.  Some projects add some additional restrictions or
privileges.

Groups can be members of other groups.  To help manage access control, in many
cases we've separated "roles" (groups to which privileges are assigned) from
specific lists of people.


#### Groups used as roles

"Change Approver Role" is a group that gets the privilege of approving changes
(voting +2).  It currently contains the "Joyent Team" group.  If we decide to
entrust community members with this privilege, we should add another group for
them, and then add that group to this role.


#### Groups with people in them

"Joyent Team" are members of the Joyent engineering team.  We do not grant
privileges to this group directly, but rather we make this group a member of
other groups that get privileges (e.g., "Change Approver Role").

"illumos mergers" are people who merge upstream changes from illumos into
illumos-joyent.  They need privileges to push merge commits to illumos-joyent.

"Administrators" are essentially super-users in the Gerrit UI.  People should
not need to be administrators in order to do day-to-day work.  We should only
add people to this group in order to help maintain cr.joyent.us, not to work
around some other access control issue.  In Gerrit's default configuration,
administrators are also super-users in Git (able to force-push, push to master,
and so on), but we have removed those privileges from this group to make it
harder for administrators to accidentally do these things.  If you need these
Git privileges, see the "Temporary Git Superusers" group.

"Temporary Git Superusers" are users with privileges to do all the git
operations that we normally don't want people to do: push directly to master
(bypassing review), force-pushing, pushing merge commits, and so on.  This group
is expected to be empty most of the time.  If you need to do one of these
operations (e.g., to import a repository), you can add yourself to this group,
do the operation, **and then remove yourself from the group**.  Obviously, this
group doesn't buy additional security, since any administrator can add
themselves to it.  It's just to prevent administrators from accidentally
overriding the safeties.


#### Groups used by the infrastructure

"GitHub (joyent) Replication Group": this group is created specifically to
manage which repositories are replicated to GitHub.  The replication process
runs as this group and replicates all repositories starting with "joyent/" that
it can read from.  All of our projects inherit from the GitHub-Joyent project,
which enables read access to this group.  This generally should not need
maintenance.

#### Note on project creation

Only administrators in Gerrit are allowed to edit projects, and editing is
essentially required during initial project setup.  As a result, we require
administrators to create or import projects.  There's a deprecated "Project
Creator Role" where we experimented with delegating this privilege.


#### Project owners

Gerrit supports project owners that have additional access rights on
repositories.  We do not use these.  The whole team (and potentially community
members to whom we delegate) have rights to approve and integrate changes on all
repositories.


## Administrative tasks

### Setting up new users

Because cr.joyent.us is on the internet and uses GitHub for authentication,
anybody can register an account and start using it.  That's by design, so that
we can code review and accept community contributions. However, only authorized
users will be able to approve changes.

New users that are employees of Joyent should be added to the ["Joyent
Team"](https://cr.joyent.us/#/admin/groups/6) group.

New users that are not employees of Joyent, but which we will trust for
approvals should be put into a new group called "External Approvers".  (This
hasn't happened yet.)  That group should in turn become a member of "Change
Approver Role".  See "Access Control" below.


### Importing repositories that are on GitHub

**Please do not create repositories by hand in the Gerrit web UI.**  It's hard
to get the settings right, and we likely won't discover if they're wrong until
something bad has already happened.

Use the [crimport](../../bin/crimport) script inside this repository to import a
repository from GitHub.  This script:

- creates a new Gerrit project with appropriate settings, including replication
  to GitHub
- clones the repository from GitHub
- pushes the repository to Gerrit

**Note:** the script may report problems pushing tags or non-master branches.
We haven't figured out yet how we're going to deal with these branches, but the
failure to push these branches doesn't affect using code review for master.

Also, **please review the user instructions for importing repositories that are
on GitHub**.  They have a bunch of important notes about how things change once
a repository is imported.


### Creating new repositories

See the user instructions "Creating a new repository".  (They basically say to
create the repository on GitHub and then treat it as an import.)

(**Please do not create repositories by hand in the Gerrit web UI.**  It's hard
to get the settings right, and we likely won't discover if they're wrong until
something bad has already happened.)


## Deployment notes

cr.joyent.us is deployed in us-west-1 (behind TLS), using CNS for internal and
external service discovery.

### Container topology

Gerrit uses both a PostgreSQL database and the local filesystem.  We use
separate data volumes for the PostgreSQL database and for the local filesystem.
There are five total containers:

- data container for the PostgreSQL database
- data container for Gerrit's local filesystem data
- PostgreSQL database
- Gerrit itself
- nginx proxy (the only thing that's public)

Originally, the data containers would never be modified or redeployed, while the
other containers could be redeployed at will (subject to the usual constraints
around on-disk formats with new versions of Gerrit or PostgreSQL).  Now, the
current deployment tools always deploy an entire new stack from a backup, so
it's less necessary to use separate data containers, but it's still convenient
for doing backup/restore and for inspecting the contents of these datasets.

### Service discovery

We've created a CNAME in public DNS for `cr.joyent.us`.  This points to a
CNS-provided DNS name for the nginx container.  This way, if we want to redeploy
the Gerrit instance, the instance IP may change, but the CNS name will be
automatically updated with the new IP address, so users of the public CNAME will
also get the new IP.  (It's not clear that Gerrit supports multiple instances
running on the same data, so rolling upgrades are likely not possible, but this
approach still makes it easy to upgrade instances.)

### GitHub authentication

To use GitHub auth, we've set up a [GitHub
application](https://github.com/organizations/joyent/settings/applications/371013).
If the public hostname changes, this needs to be updated.


### Image builds and configuration

We use two custom images:

* `joyentunsupported/joyent-gerrit:dev`: Gerrit application server
* `arekinath/gerrit-nginx`: nginx container

The appserver image is built from this repository.  See images/appserver.
There's a README.md in there that describes the configuration model in some
detail.  In short, non-deployment-specific, non-secret configuration is built
into the image.  If we want to change that, we build a new image.  This
encourages testing those kinds of configuration changes, and also would
facilitate blue-green deploys, if Gerrit supported that.


### Deployment using backup and restore

This entire stack (PostgreSQL, Gerrit, nginx, and data) can be backed up and
restored from backup using tools in the "bin" directory inside this repo.  You
can backup the production cr.joyent.us and restore it to a test environment to
test new images or configuration changes.  These tools use docker(1) and
triton(1) to locate and deploy containers.

You can have multiple deployments of the stack alongside each other in the same
datacenter.  These are distinguished by the _prefix_.  The default prefix for
backup is "gerrit" (which is the current production prefix).  You can deploy a
second copy with a different name like "gerrit-staging".  This prefix shows up
in each of the containers' names as well as their CNS service names.

The `crbackup` tool backs up the data contained in a running stack.  The
PostgreSQL database is backed up with pg\_dump and the Gerrit filesystem is
backed up as a tarball with "docker cp".  Both of these are downloaded into a
local directory that can subsequently be given to `crrestore`.

`crrestore` takes the backup directory saved by `crbackup` and redeploys the
entire stack from the data contained in the tarball.  There are basically two
modes: "production" mode and "dev" mode.  In "production" mode, the server
advertises itself as "cr.joyent.us" and has replication to GitHub enabled.  In
"dev" mode, the server advertises itself as "localhost".  To use it, you would
typically set up port forwarding on your local system.

To back up the stack:

    # Stop the application container to get a consistent backup.
    docker stop gerrit-appserver

    # Back up to local directory "./2016-06-12-0".  This looks for containers
    # with the prefix "gerrit" by default (e.g., "gerrit-appserver").  You can
    # override this with the "-n" option.
    crbackup ./2016-06-12-0

The containers representing the service are automatically located by name (e.g.,
"gerrit-appserver") using the "docker" tool.

To create a new test environment from a backup, you would typically run:

    crrestore -c CLIENT_ID -s CLIENT_SECRET ./2016-06-12-0

where CLIENT\_ID and CLIENT\_SECRET come from a GitHub oauth application that
you've set up for testing.  This is necessary because the GitHub application
configuration specifies what server it's for (e.g., https://cr.joyent.us) and
redirects clients to that server, so you cannot use the same one for testing
that we use in production.

For a production deployment, you'd leave out the "-c" and "-s" flags and add
"-p" (for "production").  It's recommended that you use "-n gerritDATESTAMP" to
create a unique group of containers.  If you do this, you'll have to manually
tag the nginx image with the appropriate CNS service name.  Here's what the
whole process looks like for a production deployment.

    # Stop the current appserver to get a consistent backup.
    docker stop gerritOLDDATE-appserver

    # Back up the existing deployment to a local directory.
    ./bin/crbackup -n gerritOLDDATE ../backups/NEWDATE

    # Deploy a new stack from the backup.
    ./bin/crrestore -p -n gerritNEWDATE ../backups/NEWDATE

    #
    # Test the new stack.  Update your /etc/hosts to point cr.joyent.us at
    # the public IP for the frontdoor container and then access the browser
    # interface.  Validate any changes you want.  Note that by the time you're
    # doing a production deployment, you likely have already validated the
    # changes in a testing deployment, so this is just a sanity check.
    #
    # When you're ready, verify that the new frontdoor container has
    # a CNS service name "gerritNEWDATE":
    #
    triton instance tag list gerritNEWDATE-frontdoor 

    # Now add the CNS service name "gerrit" as well.
    triton instance tag set gerritNEWDATE-frontdoor \
        triton.cns.services=gerritNEWDATE,gerrit

    # Now shut down the old containers.
    docker stop gerritOLDDATE-{frontdoor,postgres}

    #
    # Wait for cr.joyent.us to point to the new public IP.  The TTL on
    # cr.joyent.us is long, but the CNAME it points to should update within 30
    # seconds.
    #

**Note:** the SSL certificate for the nginx container is not currently part of
the backup/restore process, so it will always try to generate a new certificate
when you redeploy it.  This generally won't work unless you're deploying a
production version, and even then it won't work until after "cr.joyent.us"
points to the new nginx container.  At that point, it _should_ work, but we've
seen cases where it didn't.  In that case, try "docker exec" into the frontdoor
container and send SIGHUP to the nginx process.



## References

* https://github.com/openfrontier/docker-gerrit
* https://gerrit.googlesource.com/plugins/github/+/master/README.md
* https://www.packtpub.com/books/content/using-gerrit-github
* https://hub.docker.com/\_/postgres/
* Replication: https://gist.github.com/Aricg/56f1a769cbdcbb93b459


## Historical notes

From the stock openfrontier image, we got Gerrit set up by modifying:

* Mail notifications: see SMTP and USER\_EMAIL params in deployment
* GitHub auth: see AUTH/OAUTH params in deployment
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

Subsequent config changes should be documented either in this repository's
history (when the image changes) or in Git (when project configuration changes).

### Known issues

Importing platform: could not push existing platform repo to Gerrit ssh server
because of invalid commit messages.  Instead, used "docker exec", cloned repo
from GitHub, and pushed to local copy.

Attempted to create node-cueball project, but it actually created a new change
for each commit.  I haven't seen this again, so I don't know what caused it.

By attempting to remove an old version of the node-cueball project, that project
wound up in a busted state.  I couldn't access changes for it, and I couldn't
delete it.  Reports a ConcurrentModificationException.  This was in a previous
deployment; it's no longer present in the current deployment.
