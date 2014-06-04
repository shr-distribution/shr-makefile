# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BRANCH_CHROOT = master
BRANCH_CHROOT_32BIT = 32bit
BRANCH_COMMON = jansa/master-all

URL_COMMON = "http://git.shr-project.org/repo/shr-makefile.git"

# use git://, because http:// transport doesn't support --depth
URL_SHR_CHROOT = "git://git.shr-project.org/shr-chroot.git"

UPDATE_CONFFILES_ENABLED = "0"
RESET_ENABLED = "0"

CHANGELOG_ENABLED = "0"
CHANGELOG_FORMAT = "%h %ci %aN%n        %s%n"
CHANGELOG_FORMAT_REBASE = "rebase: %h %ci %aN%n                %s%n"

SETUP_DIR = "shr-core"

ifneq ($(wildcard config.mk),)
include config.mk
endif

.PHONY: show-config
show-config:
	@echo "BRANCH_CHROOT          ${BRANCH_CHROOT}"
	@echo "BRANCH_CHROOT_32BIT    ${BRANCH_CHROOT_32BIT}"
	@echo "BRANCH_COMMON          ${BRANCH_COMMON}"
	@echo "URL_COMMON             ${URL_COMMON}"
	@echo "URL_SHR_CHROOT         ${URL_SHR_CHROOT}"
	@echo ""

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
	if [ "${UPDATE_CONFFILES_ENABLED}" = "1" ] ; then \
		${MAKE} update-conffiles ; \
	fi
	if [ -d ${SETUP_DIR} ] ; then \
		if ! diff -q ${SETUP_DIR}/conf/bblayers.conf common/conf/bblayers.conf ; then \
			echo -e "\\033[1;31mWARNING: You have different bblayers.conf.\\n         Please sync it from common directory or call update-conffiles to replace all config files with new versions.\\e[0m"; \
		fi ; \
		if ! diff -q ${SETUP_DIR}/conf/layers.txt common/conf/layers.txt; then \
			echo -e "\\033[1;31mWARNING: You have different layers.txt.\\n         Please sync it from common directory or call update-conffiles to replace all config files with new versions.\\e[0m"; \
		fi ; \
		if ! diff -q ${SETUP_DIR}/conf/site.conf common/conf/site.conf; then \
			echo -e "\\033[1;31mWARNING: You have different site.conf\\n         Please sync it from common directory or call update-conffiles to replace all config files with new versions.\\e[0m"; \
		fi ; \
		[ -e scripts/oebb.sh ] && ( OE_SOURCE_DIR=`pwd`/${SETUP_DIR} scripts/oebb.sh update ) ; \
		if [ "${RESET_ENABLED}" = "1" ] ; then \
			[ -e scripts/oebb.sh ] && ( OE_SOURCE_DIR=`pwd`/${SETUP_DIR} scripts/oebb.sh reset ) ; \
		fi; \
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
	  git clone ${URL_COMMON} common && \
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
	@echo "preparing ${SETUP_DIR} tree"
	[ -d ${SETUP_DIR} ] || ( mkdir -p ${SETUP_DIR} )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -d scripts ] || ( cp -ra common/scripts scripts )
	[ -L ${SETUP_DIR}/bitbake ] && rm -f ${SETUP_DIR}/bitbake || echo "bitbake is not a symlink"
	[ -e ${SETUP_DIR}/setup-env ] || ( cd ${SETUP_DIR} ; ln -sf ../common/setup-env . )
	[ -e ${SETUP_DIR}/setup-local ] || ( cd ${SETUP_DIR} ; cp ../common/setup-local . )
	[ -e ${SETUP_DIR}/downloads ] || ( cd ${SETUP_DIR} ; ln -sf ../downloads . )
	[ -d ${SETUP_DIR}/conf ] || ( cp -ra common/conf ${SETUP_DIR}/conf )
	[ -e ${SETUP_DIR}/conf/layers.txt ] || ( cp -ra common/conf/layers.txt ${SETUP_DIR}/conf )
	[ -e ${SETUP_DIR}/conf/topdir.conf ] || echo "TOPDIR='`pwd`/${SETUP_DIR}'" > ${SETUP_DIR}/conf/topdir.conf
	[ -e scripts/oebb.sh ] && ( OE_SOURCE_DIR=`pwd`/${SETUP_DIR} scripts/oebb.sh update )
	touch ${SETUP_DIR}/.configured

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

.PHONY: update-conffiles
update-conffiles:
	[ -d ${SETUP_DIR}/conf ] && ( \
	  echo "syncing ${SETUP_DIR} config files up to date"; \
	  cp common/conf/auto.conf ${SETUP_DIR}/conf/auto.conf; \
	  cp common/conf/bblayers.conf ${SETUP_DIR}/conf/bblayers.conf; \
	  cp common/conf/layers.txt ${SETUP_DIR}/conf/layers.txt; \
	  cp common/conf/site.conf ${SETUP_DIR}/conf/site.conf; \
	  cp common/scripts/* scripts/; \
	)

# End of Makefile
