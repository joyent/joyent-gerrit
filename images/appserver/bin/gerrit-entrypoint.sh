#!/bin/bash

#
# gerrit-entrypoint.sh: start up the Gerrit container.
#
# This script is responsible for:
#
#    (1) verifying that a valid Gerrit site directory is present
#
#    (2) verifying that runtime parameters have been set
#
#    (3) synthesizing the complete Gerrit configuration based on the basic
#        configuration supplied in this image and the runtime parameters.
#
#    (4) make sure that the software (gerrit.war and plugin jar files),
#        configuration, and shared secrets are put into the right places.
#

set -o xtrace
set -o errexit
set -o pipefail

function main
{
	if [[ -z "$GERRIT_USER" ]] ||
	   [[ -z "$GERRIT_HOME" ]] ||
	   [[ -z "$GERRIT_SITE" ]]; then
		fail "expected GERRIT_USER, GERRIT_HOME, and GERRIT_SITE to" \
		    "be set in the environment"
	fi

	if [[ -z "$JG_DATABASE_HOSTNAME" ]] ||
	   [[ -z "$JG_CANONICALWEBURL" ]] ||
	   [[ -z "$JG_JOYENT_ENABLE_REPLICATION" ]]; then
		fail "expected Gerrit configuration parameters" \
		    "(see image README.md)"
	fi

	if [[ -z "$JG_SENDEMAIL_SMTPSERVER" ]] ||
	   [[ -z "$JG_SSHD_ADVERTISEDADDRESS" ]] ||
	   [[ -z "$JG_HTTPD_LISTENURL" ]] ||
	   [[ -z "$JG_USER_EMAIL" ]]; then
	   	echo "warn: some Gerrit configuration parameters were" \
		    "unspecified" >&2
	fi

	if [[ ! -d "$GERRIT_SITE" || ! -d "$GERRIT_SITE/etc" ]]; then
		fail "does not appear to be a site: $GERRIT_SITE"
	fi

	#
	# If we're running on SmartOS, work around OS-5498 by installing the
	# native copies of cp(1) and cat(1) in place of the Alpine ones.  We
	# have to be careful how we do this, since /bin/cp and /bin/cat may be
	# symlinks to /bin/busybox in this image.
	#
	if [[ -f /native/usr/bin/cp ]]; then
		if ! ln -f -s /native/usr/bin/cp /bin/cp ||
		   ! ln -f -s /native/usr/bin/cat /bin/cat; then
			fail "failed to workaround OS-5498"
		fi
	fi

	#
	# Generate our complete configuration.  Start with the configuration
	# shipped with the image.
	#
	mkdir -p $GERRIT_HOME/gen
	cp $GERRIT_HOME/shipped/gerrit.config.base \
	    $GERRIT_HOME/gen/gerrit.config

	# Apply the optional runtime configuration parameters.
	[[ -n "$JG_SENDEMAIL_SMTPSERVER" ]] &&
	    gerrit_set sendemail.smtpServer   "$JG_SENDEMAIL_SMTPSERVER"
	[[ -n "$JG_SSHD_ADVERTISEDADDRESS" ]] &&
	    gerrit_set sshd.advertisedAddress "$JG_SSHD_ADVERTISEDADDRESS"
	[[ -n "$JG_HTTPD_LISTENURL" ]] &&
	    gerrit_set httpd.listenUrl        "$JG_HTTPD_LISTENURL"
	[[ -n "$JG_USER_EMAIL" ]] &&
	    gerrit_set user.email             "$JG_USER_EMAIL"

	# Apply the required runtime configuration parameters.
	gerrit_set gerrit.canonicalWebUrl "$JG_CANONICALWEBURL"
	gerrit_set database.hostname      "$JG_DATABASE_HOSTNAME"
	if [[ "$JG_JOYENT_ENABLE_REPLICATION" == "true" ]]; then
		cp $GERRIT_HOME/shipped/replication.config \
		    $GERRIT_HOME/gen/replication.config
	fi

	chown -R gerrit2 $GERRIT_HOME/gen

	#
	# Users can specify that the secure GitHub credentials be overridden so
	# that they can use a different GitHub configuration (e.g., for a
	# staging environment).  This is not intended for real deployments.
	# They will use the existing file on the shared volume that contains the
	# production client id and secret.  This operation will change that, so
	# it won't work to try to use the same shared volume with different
	# sets of GitHub parameters.
	#
	if [[ -n "$JG_GITHUB_CLIENT_ID" ]] &&
	   [[ -n "$JG_GITHUB_CLIENT_SECRET" ]]; then
		echo "NOTE: Overriding GitHub client ID and secret."
		gerrit_set_secure \
		    plugin.gerrit-oauth-provider-github-oauth.client-id \
		    "$JG_GITHUB_CLIENT_ID"
		gerrit_set_secure \
		    plugin.gerrit-oauth-provider-github-oauth.client-secret \
		    "$JG_GITHUB_CLIENT_SECRET"
		chown gerrit2 $GERRIT_SITE/etc/secure.config
	fi

	#
	# Recall that:
	#
	#    - $GERRIT_HOME is part of the image that we've built.
	#
	#    - $GERRIT_SITE is part of a volume mounted in at runtime.
	#
	# The volume contains most of the directories and files Gerrit needs in
	# order to run, including the copies of the Git repositories.  Ideally,
	# the volume would not contain code, binaries, or non-shared-secret
	# configuration.  These would come from the image, where they can be
	# managed like software (under revision control and with repeatable
	# builds).
	#
	# In general, when there's an item that Gerrit expects under
	# $GERRIT_SITE but that we prefer to come from the image, we create a
	# symlink under $GERRIT_SITE to a path inside the image.  We do this
	# for:
	#
	#    - non-secret configuration: $GERRIT_SITE/etc/gerrit.config and
	#      $GERRIT_SITE/etc/replication.config
	#
	#    - plugins: $GERRIT_SITE/plugins
	#
	#    - lib: $GERRIT_SITE/lib
	#
	# We may want to add more of these in the future.
	#
	# The original deployment of gerrit.joyent.us did not work this way, so
	# we have one-time flag-day code to update it.  We don't want to throw
	# anything away, in case this doesn't work.
	#
	if ! [[ -L $GERRIT_SITE/etc/gerrit.config ]] ||
	   ! [[ -L $GERRIT_SITE/etc/replication.config ]] ||
	   ! [[ -L $GERRIT_SITE/lib ]] ||
	   ! [[ -L $GERRIT_SITE/plugins ]]; then
		echo "Found non-symlinked paths.  Assuming old layout."
		echo "Will move existing files to $GERRIT_SITE/archive."

		#
		# If our archive directory already exists, bail out.  We could
		# make this idempotent, but to avoid clobbering data we'd want
		# to check each individual file for differences.  It's easier to
		# make the user resolve this unusual case.
		#
		if [[ -d $GERRIT_SITE/archive ]]; then
			fail "$GERRIT_SITE/archive already exists"
		fi

		mkdir $GERRIT_SITE/archive

		if ! [[ -L $GERRIT_SITE/etc/gerrit.config ]]; then
			cp $GERRIT_SITE/etc/gerrit.config $GERRIT_SITE/archive
			ln -f -s $GERRIT_HOME/gen/gerrit.config \
			    $GERRIT_SITE/etc/gerrit.config
		fi

		if ! [[ -L $GERRIT_SITE/etc/replication.config ]]; then
			cp $GERRIT_SITE/etc/replication.config \
			    $GERRIT_SITE/archive
			ln -f -s $GERRIT_HOME/gen/replication.config \
			    $GERRIT_SITE/etc/replication.config
		fi

		if ! [[ -L $GERRIT_SITE/lib ]]; then
			mv $GERRIT_SITE/lib $GERRIT_SITE/archive
			ln -s $GERRIT_HOME/shipped/lib $GERRIT_SITE/lib
		fi

		if ! [[ -L $GERRIT_SITE/plugins ]]; then
			mv $GERRIT_SITE/plugins $GERRIT_SITE/archive
			ln -s $GERRIT_HOME/shipped/plugins $GERRIT_SITE/plugins
		fi
	fi

	#
	# There's also a case of the opposite: the .ssh directory needs to exist
	# under $GERRIT_HOME, but its contents comes from the volume because it
	# includes shared secrets that we don't want to build into the image.
	# For this, we create a symlink under $GERRIT_HOME to the appropriate
	# path inside the volume.
	#
	if ! [[ -L "$GERRIT_HOME/.ssh" ]]; then
		if [[ -e "$GERRIT_HOME/.ssh" ]]; then
			fail "unexpected $GERRIT_HOME/.ssh in the image"
		fi

		ln -s $GERRIT_SITE/ssh-joyent $GERRIT_HOME/.ssh
	fi

	#
	# Historically, the Gerrit user's numeric uid changed across different
	# image versions, though we've now settled on one that's encoded in the
	# Dockerfile.  For now, make sure everything is owned by the right user.
	# We should be able to remove this once we've backed up a site that was
	# created with the new uid.
	#
	chown -R gerrit2 $GERRIT_SITE

	exec "$@"
}

function fail
{
	echo "gerrit-entrypoint.sh: $@"
	exit 1
}

#
# gerrit_set KEY VALUE: set a variable in the generated Gerrit configuration
# file.
#
function gerrit_set
{
	gerrit_set_file "${GERRIT_HOME}/gen/gerrit.config" "$1" "$2"
}

#
# gerrit_set_file FILE KEY VALUE: set a variable in the specified configuration
# file.
#
function gerrit_set_file
{
	git config -f "$1" "$2" "$3"
}

#
# gerrit_set_secure KEY VALUE: set a variable in the _secure_ configuration
# file.  Note that this is stored on the shared volume, so this will potentially
# affect future deployments.
#
function gerrit_set_secure
{
	gerrit_set_file "${GERRIT_SITE}/etc/secure.config" "$1" "$2"
}

main "$@"
