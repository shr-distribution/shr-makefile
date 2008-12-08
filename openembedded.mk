#!/bin/make
# Makefile for OpenEmbedded builds
# Licensed under the GPL v2 or later
#
# conf/auto.conf must exist in the same directory as the Makefile (i.e.
# the directory where Makefile is used - it may be a symbolic link to
# this file).  conf/auto.conf defines:
#
# DISTRO - the OpenEmbedded 'distro' to build
# MACHINE - the OpenEmbedded build target machine
#
# All of these values are (should be, must be) quoted in double quotes
include conf/auto.conf

BUILD_DIRS = downloads
REQUIRED_DIRS = bitbake openembedded
FIRMWARE_DEPS = create-topdir $(BUILD_DIRS) $(REQUIRED_DIRS)
BITBAKE = bitbake

image: $(FIRMWARE_DEPS)
ifdef IMAGE_TARGET
	. ./setup-env; exec ${BITBAKE} $(IMAGE_TARGET)
else
	. ./setup-env; exec ${BITBAKE} $(DISTRO)-image
endif

distro: $(FIRMWARE_DEPS)
ifdef DISTRO_TARGET
	. ./setup-env; exec ${BITBAKE} $(DISTRO_TARGET)
else
	. ./setup-env; exec ${BITBAKE} $(DISTRO)-packages
endif

kernel: $(FIRMWARE_DEPS)
ifdef KERNEL_TARGET
	. ./setup-env; exec ${BITBAKE} $(KERNEL_TARGET)
else
	. ./setup-env; exec ${BITBAKE} virtual/kernel
endif

index:
	. ./setup-env; exec ${BITBAKE} package-index

prefetch: $(FIRMWARE_DEPS)
ifdef DISTRO_TARGET
	. ./setup-env; exec ${BITBAKE} -cfetch $(DISTRO_TARGET)
else
	. ./setup-env; exec ${BITBAKE} -cfetch $(DISTRO)-packages
endif

# topdir.conf is re-created automatically if the directory is
# moved - this will cause a full bitbake reparse
.PHONY: create-topdir
create-topdir: conf/topdir.conf
	. conf/topdir.conf && test "`pwd`" = "$$TOPDIR" || echo "TOPDIR='`pwd`'" > conf/topdir.conf

conf/topdir.conf:
	echo "TOPDIR='`pwd`'" >$@

# rules for directories - if a symlink exists and the target does not
# exist something will go wrong in the build, therefore cause a failure
# here by the mkdir.
$(BUILD_DIRS):
	test -d $@ || if test -d ../$@; then ln -s ../$@ .; else mkdir $@; fi

# these directories must already exist - either in TOPDIR (here) or in ..
$(REQUIRED_DIRS):
	test -d $@ || if test -d ../$@; then ln -s ../$@ .; else exit 1; fi

.PHONY: setup-machine-%
setup-machine-%:
	( grep "MACHINE = \"$*\"" conf/auto.conf > /dev/null ) || \
	sed -i -e 's/^MACHINE[[:space:]]*=[[:space:]]*\".*\"/MACHINE = \"$*\"/' conf/auto.conf

.PHONY: setup-distro-%
setup-distro-%:
	( grep "DISTRO = \"$*\"" conf/auto.conf > /dev/null ) || \
	sed -i -e 's/^DISTRO[[:space:]]*=[[:space:]]*\".*\"/DISTRO = \"$*\"/' conf/auto.conf

.PHONY: setup-image-%
setup-image-%:
	( grep "IMAGE_TARGET = \"$*\"" conf/auto.conf > /dev/null ) || \
	sed -i -e 's/^IMAGE_TARGET[[:space:]]*=[[:space:]]*\".*\"/IMAGE_TARGET = \"$*\"/' conf/auto.conf

.PHONY: setup-packages-%
setup-packages-%:
	( grep "DISTRO_TARGET = \"$*\"" conf/auto.conf > /dev/null ) || \
	sed -i -e 's/^DISTRO_TARGET[[:space:]]*=[[:space:]]*\".*\"/DISTRO_TARGET = \"$*\"/' conf/auto.conf

.PHONY: clobber
clobber:
	rm -rf tmp

.PHONY: source
source: $(REQUIRED_DIRS)
	tar zcf $(DISTRO).tar.gz --exclude=MT --exclude=.svn Makefile setup-env \
		conf/site.conf conf/auto.conf conf/local.conf.sample $(REQUIRED_DIRS:=/.)

# This target probably isn't important any longer, because the -source
# target above does the right thing
.PHONY:
distclean: clobber
	rm -rf conf/topdir.conf conf/local.conf $(BUILD_DIRS)

# This target is mainly for testing - it is intended to put the disto directory
# back to its original state, it will destroy a source-tarball system (because
# it removes directories from the tarball).
.PHONY:
really-clean: distclean
	rm -rf $(REQUIRED_DIRS) $(DISTRO)-source.tar.gz
