* Import documentation and script need to be updated for repos with merge
  commits.
* Add image builds to this repository
* Clean up stuff in staging environment
* Backup and restore scripts need cleaning up
* consider building our own image instead of using the openfrontier one
  - theirs reconfigures every time, even though config is on data volume
  - theirs seems to change out from under us in incompatible ways
* Would be nice to have an option to avoid eliminating votes each time a new
  review is submitted?  This presumably needs to be optional.  Sometimes you
  want the votes to carry over (e.g., a commit message nit), and sometimes you
  don't.
* Would be nice to have a plugin to auto-update commit message with reviewers
  and approved-by (without the other metadata that Gerrit likes to add)
* backup story for github repos?
* are the "project owner" settings what we want?
* auto-import people's public keys and email addresses from GitHub?
* set up commit message validation
* set up jenkins integration for 'make check'
* set up jenkins integration for 'make test'
* any kind of monitoring?
* move to docker compose or some other way to keep track of the whole app?
