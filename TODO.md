High priority:
* Try 2.12.2 + patch to fix the login bug people are hitting
* Add nginx image to this repository

RFEs:
* add "reviewers" plugin for setting per-project default reviewers
* plugin to automatically add first ticket identifier as a change's topic?
* plugin for commit message validation
* plugin to auto-update commit message with reviewers and approved-by
  (without the other metadata that Gerrit likes to add)
* set up jenkins integration for 'make check'
* set up jenkins integration for 'make test'
* auto-import people's public keys and email addresses from GitHub?

Other:
* backup story for github repos?
* any kind of monitoring?
* look at ContainerPilot
* look at docker compose or some other way to keep track of the whole app
