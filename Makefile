# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BRANCH_CHROOT = master
BRANCH_CHROOT_32BIT = 32bit
BRANCH_COMMON = master

URL_SHR_MAKEFILE = "http://git.shr-project.org/repo/shr-makefile.git"

# use git://, because http:// transport doesn't support --depth
URL_SHR_CHROOT = "git://git.shr-project.org/shr-chroot.git"

CHANGELOG_ENABLED = "0"
CHANGELOG_FORMAT = "%h %ci %aN%n        %s%n"
CHANGELOG_FORMAT_REBASE = "rebase: %h %ci %aN%n                %s%n"

ifneq ($(wildcard config.mk),)
include config.mk
endif

.PHONY: show-config
show-config:
	@echo "BRANCH_CHROOT          ${BRANCH_CHROOT}"
	@echo "BRANCH_CHROOT_32BIT    ${BRANCH_CHROOT_32BIT}"
	@echo "BRANCH_COMMON          ${BRANCH_COMMON}"
	@echo "URL_SHR_MAKEFILE       ${URL_SHR_MAKEFILE}"
	@echo "URL_SHR_CHROOT         ${URL_SHR_CHROOT}"
	@echo ""

.PHONY: all
all: update build

.PHONY: changelog
changelog:
	[ ! -e ../.git/config-32bit ] || ${MAKE} changelog-shr-chroot-32bit 
	[ ! -e ../.git/config-64bit ] || ${MAKE} changelog-shr-chroot 
	[ ! -e common ]            || ${MAKE} changelog-common 

.PHONY: update
update: 
	if [ "${CHANGELOG_ENABLED}" = "1" ] ; then \
		${MAKE} changelog ; \
	fi
	[ ! -e common ]       || ${MAKE} update-common 
	if [ -d shr-core ] ; then \
		[ -e scripts/oebb.sh ] && ( OE_SOURCE_DIR=`pwd`/shr-core scripts/oebb.sh update ) ; \
		if ! diff -q shr-core/conf/bblayers.conf common/conf/bblayers.conf ; then \
			echo -e "\\033[1;31m" "WARNING: you have different bblayers.conf, please sync it from common directory or call update-conffiles to replace all config files with new versions" ; \
		fi ; \
		if ! diff -q shr-core/conf/layers.txt common/conf/layers.txt; then \
			echo -e "\\033[1;31m" "WARNING: you have different layers.txt, please sync it from common directory or call update-conffiles to replace all config files with new versions" ; \
			echo -e "\\e[0m" ; \
		fi ; \
	fi

.PHONY: setup-shr-chroot
.PRECIOUS: shr-chroot/.git/config-64bit
setup-shr-chroot shr-chroot/.git/config-64bit:
	[ -e shr-chroot/.git/config-64bit ] || \
	( echo "setting up shr-chroot ..."; \
	  git clone --no-checkout --depth 1 ${URL_SHR_CHROOT} shr-chroot; \
	  cd shr-chroot; \
	  git checkout ${BRANCH_CHROOT} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_CHROOT} origin/${BRANCH_CHROOT} ; \
	  git reset --hard origin/${BRANCH_CHROOT}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)
	mv Makefile shr-chroot/OE/Makefile
	touch shr-chroot/.git/config-64bit
	echo "Now run shr-chroot.sh in shr-chroot as ROOT to switch to new SHR chroot environment"

.PHONY: setup-shr-chroot-32bit
.PRECIOUS: shr-chroot-32bit/.git/config-32bit
setup-shr-chroot-32bit shr-chroot-32bit/.git/config-32bit:
	[ -e shr-chroot-32bit/.git/config-32bit ] || \
	( echo "setting up shr-chroot-32bit ..."; \
	  git clone --no-checkout --depth 1 ${URL_SHR_CHROOT} shr-chroot-32bit; \
	  cd shr-chroot-32bit; \
	  git checkout ${BRANCH_CHROOT_32BIT} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_CHROOT_32BIT} origin/${BRANCH_CHROOT_32BIT} ; \
	  git reset --hard origin/${BRANCH_CHROOT_32BIT}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)
	mv Makefile shr-chroot-32bit/OE/Makefile
	touch shr-chroot-32bit/.git/config-32bit
	echo "Now run shr-chroot.sh in shr-chroot-32bit as ROOT to switch to new SHR chroot environment"

.PHONY: setup-common
.PRECIOUS: common/.git/config
setup-common common/.git/config:
	[ -e common/.git/config ] || \
	( echo "setting up common (Makefile)"; \
	  git clone ${URL_SHR_MAKEFILE} common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	( cd common && \
	  git checkout ${BRANCH_COMMON} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_COMMON} origin/${BRANCH_COMMON} )
	touch common/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured

.PRECIOUS: shr-core/.configured
shr-core/.configured: common/.git/config
	@echo "preparing shr-core tree"
	[ -d shr-core ] || ( mkdir -p shr-core )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -d scripts ] || ( cp -ra common/scripts scripts )
	[ -e shr-core/setup-env ] || ( cd shr-core ; ln -sf ../common/setup-env . )
	[ -e shr-core/setup-local ] || ( cd shr-core ; cp ../common/setup-local . )
	[ -e shr-core/downloads ] || ( cd shr-core ; ln -sf ../downloads . )
	[ -d shr-core/conf ] || ( cp -ra common/conf shr-core/conf )
	[ -e shr-core/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-core'" > shr-core/conf/topdir.conf
	[ -e scripts/oebb.sh ] && ( OE_SOURCE_DIR=`pwd`/shr-core scripts/oebb.sh update )
	touch shr-core/.configured

.PHONY: changelog-shr-chroot
changelog-shr-chroot: ../.git/config-64bit
	@echo "Changelog for shr-chroot (64bit)"
	( cd .. ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_CHROOT} )

.PHONY: changelog-shr-chroot-32bit
changelog-shr-chroot-32bit: ../.git/config-32bit
	@echo "Changelog for shr-chroot (32bit)"
	( cd ,, ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_COMMON_32BIT} )

.PHONY: changelog-common
changelog-common: common/.git/config
	@echo "Changelog for common (Makefile)"
	( cd common ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_COMMON} )

.PHONY: update-common
update-common: common/.git/config
	@echo "updating common (Makefile)"
	( cd common ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_COMMON} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_COMMON} origin/${BRANCH_COMMON} ; \
	  git reset --hard origin/${BRANCH_COMMON}; \
	)
	( echo "replacing Makefile with link to common/Makefile"; \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )

.PHONY: update-shr-chroot
update-shr-chroot: ../.git/config-64bit
	@echo "updating shr-chroot"
	[ -e ../.git/config-64bit ] || ( echo "There should be ../.git/config-64bit if you have shr-chroot" && exit 1 )
	( cd .. ; \
	  git fetch ; \
	  git checkout ${BRANCH_CHROOT} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_CHROOT} origin/${BRANCH_CHROOT} ; \
	  git reset --hard origin/${BRANCH_CHROOT}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)

.PHONY: update-shr-chroot-32bit
update-shr-chroot-32bit: ../.git/config-32bit
	@echo "updating shr-chroot-32bit"
	[ -e ../.git/config-32bit ] || ( echo "There should be ../.git/config-32bit if you have shr-chroot-32bit" && exit 1 )
	( cd .. ; \
	  git fetch ; \
	  git checkout ${BRANCH_CHROOT_32BIT} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_CHROOT_32BIT} origin/${BRANCH_CHROOT_32BIT} ; \
	  git reset --hard origin/${BRANCH_CHROOT_32BIT}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)

update-conffiles: shr-core/.configured
	@echo "syncing shr-core config files up to date"
	cp common/conf/auto.conf shr-core/conf/auto.conf
	cp common/conf/bblayers.conf shr-core/conf/bblayers.conf
	cp common/conf/layers.txt shr-core/conf/layers.txt
	cp common/conf/site.conf shr-core/conf/site.conf

# End of Makefile
