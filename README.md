# joyent-gerrit: cr.joyent.us code review infrastructure

This repository contains tools, documentation, and Dockerfiles for Joyent's code
review infrastructure at [cr.joyent.us](https://cr.joyent.us).

**If you're looking for instructions on using the infrastructure as a
contributor or project owner, see the [user
instructions](docs/user/README.md).**  There's also [documentation for operators](docs/operator/README.md).

Directories here include:

* `bin`: tools for backing up the infrastructure, standing up a new stack based
  on a backup, and importing repositories from GitHub.
* `docs`: documentation for both users (contributors and project owners) and
  operators
* `images`: Dockerfiles and support files for creating the Docker images used in
  the stack
* `tools/mk`: stock Joyent Makefile hunks

This repository itself is managed by
[cr.joyent.us](https://cr.joyent.us/#/q/project:joyent/joyent-gerrit).
