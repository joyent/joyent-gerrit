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

- configures the GitHub repository to only allow Gerrit to push to master
- creates a new Gerrit project with appropriate settings, including replication
  to GitHub
- clones the repository from GitHub
- pushes the repository to Gerrit

Before running this script you will need to [create a GitHub API token](https://github.com/settings/tokens)
and place it into a `~/.github-api-token` file locally, so that the script can
take care of updating GitHub.

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


### Using `git gc` on `illumos-joyent`

Gerrit git repositories need to be regularly garbage-collected, as the review
process often results in quite a lot of dangling commits and sub-optimal pack
structures. Gerrit itself does not do any automatic periodic garbage collection,
and today we run this by hand on an as-needed basis.

While most repositories in Gerrit currently can be garbage collected by running
`gerrit gc` via the SSH interface, the `illumos-joyent` repo is too large for
this tool to run. If you start a `gerrit gc` on `illumos-joyent` it will run
for around 6-12 hours while making the Gerrit server very slow and is likely to
eventually crash it.

In accordance with the Gerrit documentation, you can run `git gc` by hand in
the repository directly for cases like this. This is best done by logging into
the Gerrit zone using `docker exec` and running it in the `illumos-joyent.git`
directory as follows:

    $ docker ps
    CONTAINER ID     IMAGE                                 COMMAND                  CREATED          STATUS           PORTS            NAMES
    455e52055eb3     arekinath/gerrit-nginx                "/usr/sbin/nginx"        2 years ago      Up 10 weeks      0.0.0.0:22 ...   gerrit20160920-frontdoor
    ca325bd2b974     joyentunsupported/joyent-gerrit:dev   "/gerrit-entrypoint.…"   2 years ago      Up 9 days                         gerrit20160920-appserver
    88eb813b4fef     postgres:9.5.3                        "/docker-entrypoint.…"   2 years ago      Up 9 months      5432/tcp         gerrit20160920-postgres

    $ docker exec -it ca325bd2b974 /bin/bash --login
    ca325bd2b974:/# su -l -s /bin/bash gerrit2
    ca325bd2b974:~$ id
    uid=10000(gerrit2) gid=65533(nogroup) groups=65533(nogroup),65533(nogroup)

    ca325bd2b974:~$ cd /var/gerrit/review_site/git/joyent/illumos-joyent.git/
    ca325bd2b974:~/review_site/git/joyent/illumos-joyent.git$ git gc --aggressive
    Counting objects: 518370, done.
    Delta compression using up to 48 threads.
    Compressing objects: 100% (93549/93549), done.
    Writing objects: 100% (518370/518370), done.
    Total 518370 (delta 387262), reused 518316 (delta 387208)
    Checking connectivity: 518577, done.

It's important to make sure to use the `su` command to change to the `gerrit2`
user (and make sure to give the `-s /bin/bash` option!), or else you will mess
up permissions on parts of the git repo on disk (if you do so the first thing
you'll likely notice is that pushes of new reviews stop working -- reading
existing reviews is likely to still work, so don't rely on just doing that to
test if you're unsure whether you messed it up).


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

**Backing up the stack:**

To back up the stack:

    # Stop the application container to get a consistent backup.
    docker stop gerrit-appserver

    # Back up to local directory "./2016-06-12-0".  This looks for containers
    # with the prefix "gerrit" by default (e.g., "gerrit-appserver").  You can
    # override this with the "-n" option.
    crbackup ./2016-06-12-0

The containers representing the service are automatically located by name (e.g.,
"gerrit-appserver") using the "docker" tool.

Production backups are stored in Manta under
`/Joyent_Dev/stor/backups/cr.joyent.us`.  You'll need to download one of these
backup directories to use them with the `crrestore` tool.

**Creating a test environment:**

To create a new test environment from a backup, you'll first need to create a
GitHub oauth application that you can use for testing.  This is necessary
because the GitHub application configuration specifies where to redirect clients
after authentication (e.g., https://cr.joyent.us), and that value is necessarily
different for your test environment than for production.

You can set up the application in GitHub under your "Settings", under "OAuth
applications" on the left, then the "Developer Applications" tab, then the
"Register a new application" button.  The key piece of data is the
"Authorization callback URL", which should be "https://localhost" to match the
configuration for a test deployment.  You can reuse this application for all of
your testing.

To deploy the test stack from a backup on Triton, use:

    $ crrestore -n gerrit-test -c CLIENT_ID -s CLIENT_SECRET /path/to/local/backup/directory

where CLIENT\_ID and CLIENT\_SECRET come from the GitHub OAuth application that
you set up above.  You can leave off the "-n" option to have the tool pick a
likely-unique prefix instead.  `/path/to/local/backup/directory` is the path to
a directory on your system containing a backup created with crbackup.

The advertised hostname of the test deployment is `localhost`.  The service
exposes ports 443 (HTTPS) for access to the web application and 22 (SSH) for a
captive CLI interface to Gerrit.  To use these in the way that the service
advertises them, you'll need to forward TCP connections made to port 443 on the
localhost interface of your workstation to port 443 of the "frontdoor" container
IP.  You'll also need to forward port 30023 on the same interface to port 22 on
the same container IP.  (You can pick another ssh port if you want, but the web
UI is configured to advertise 30023.  You can also pick another HTTPS port, but
you'll need to update your GitHub OAuth application's configuration
accordingly.)

You can obtain the container's IP using `docker inspect`:

    $ docker inspect gerrit-test-frontdoor | json 0.NetworkSettings.IPAddress
    10.0.0.35

ssh provides an easy way to forward the ports by connecting to your own
workstation and setting up a tunnel:

    $ sudo ssh -L443:10.0.0.35:443 -L30023:10.0.0.35:22 localhost

This will allow you to use `https://localhost` in the browser to access the
Gerrit web interface and to use ssh to port 30023 on localhost to access the ssh
interface (including git).  The "crrestore" tool configures the application to
advertise the corresponding HTTPS and SSH ports on localhost when it displays
instructions to end users.

**Implementation note:** Instead of using localhost, we could change this to
use any other non-public DNS name and document that people update /etc/hosts
with the DNS name in order to use it.  This might be more flexible (and
clearer), but requires that extra step.  You cannot just use IP addresses
because you have to tell the Gerrit server at deployment-time which hostname or
IP address to advertise on.


**Creating a production deployment:**

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
