#
# Makefile for building a Docker image for the cr.joyent.us appserver container.
#

DOCKER             ?= docker
DOCKER_BUILD_FLAGS ?= 
TAG                ?= joyentunsupported/joyent-gerrit:dev

image:
	docker build $(DOCKER_BUILD_FLAGS) --tag=$(TAG) .
