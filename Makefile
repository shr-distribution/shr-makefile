# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BITBAKE_VERSION = master
BRANCH_CHROOT = master
BRANCH_CHROOT_32BIT = 32bit
BRANCH_COMMON = master

BRANCH_OE_CORE = shr
BRANCH_META_OE = shr
BRANCH_META_SMARTPHONE = shr
BRANCH_META_BROWSER = master

URL_OE_CORE = "git://git.openembedded.org/openembedded-core-contrib"
URL_OE_CORE_UP = "git://git.openembedded.org/openembedded-core"
URL_SHR_MAKEFILE = "http://git.shr-project.org/repo/shr-makefile.git"

# use git://, because http:// transport doesn't support --depth
URL_SHR_CHROOT = "git://git.shr-project.org/shr-chroot.git"
URL_META_SMARTPHONE = "git://git.shr-project.org/meta-smartphone.git"
URL_META_OE = "git://git.openembedded.org/meta-openembedded-contrib"
URL_META_OE_UP = "git://git.openembedded.org/meta-openembedded"

URL_META_BROWSER = "git://github.com/OSSystems/meta-browser.git"

CHANGELOG_ENABLED = "0"
CHANGELOG_FORMAT = "%h %ci %aN%n        %s%n"
CHANGELOG_FORMAT_REBASE = "rebase: %h %ci %aN%n                %s%n"

ifneq ($(wildcard config.mk),)
include config.mk
endif

.PHONY: show-config
show-config:
	@echo "BITBAKE_VERSION        ${BITBAKE_VERSION}"
	@echo "BRANCH_CHROOT          ${BRANCH_CHROOT}"
	@echo "BRANCH_CHROOT_32BIT    ${BRANCH_CHROOT_32BIT}"
	@echo "BRANCH_COMMON          ${BRANCH_COMMON}"
	@echo ""
	@echo "BRANCH_OE_CORE         ${BRANCH_OE_CORE}"
	@echo "BRANCH_META_OE         ${BRANCH_META_OE}"
	@echo "BRANCH_META_SMARTPHONE ${BRANCH_META_SMARTPHONE}"
	@echo "BRANCH_META_BROWSER    ${BRANCH_META_BROWSER}"
	@echo ""
	@echo "URL_OE_CORE            ${URL_OE_CORE}"
	@echo "URL_SHR_MAKEFILE       ${URL_SHR_MAKEFILE}"
	@echo ""
	@echo "URL_SHR_CHROOT         ${URL_SHR_CHROOT}"
	@echo "URL_META_SMARTPHONE    ${URL_META_SMARTPHONE}"
	@echo "URL_META_OE            ${URL_META_OE}"
	@echo "URL_META_BROWSER       ${URL_META_BROWSER}"
	@echo ""

.PHONY: all
all: update build

.PHONY: changelog
changelog:
	[ ! -e ../.git/config-32bit ] || ${MAKE} changelog-shr-chroot-32bit 
	[ ! -e ../.git/config-64bit ] || ${MAKE} changelog-shr-chroot 
	[ ! -e common ]            || ${MAKE} changelog-common 
	[ ! -e openembedded-core ] || ${MAKE} changelog-openembedded-core
	[ ! -e meta-openembedded ] || ${MAKE} changelog-meta-openembedded
	[ ! -e meta-smartphone ]   || ${MAKE} changelog-meta-smartphone
	[ ! -e meta-browser ]      || ${MAKE} changelog-meta-browser
	[ ! -e bitbake ]      || ${MAKE} changelog-bitbake

.PHONY: update
update: 
#       don't update shr-chroot automatically, let user to umount all binds
#	[ ! -e ../.git/config-32bit ] || ${MAKE} update-shr-chroot-32bit 
#	[ ! -e ../.git/config-64bit ] || ${MAKE} update-shr-chroot 
	if [ "${CHANGELOG_ENABLED}" = "1" ] ; then \
		${MAKE} changelog ; \
	fi
	[ ! -e common ]       || ${MAKE} update-common 
	if [ -d shr-core/openembedded-core ] && [ ! -d openembedded-core ] ; then \
		echo "Moving openembedded-core checkout from shr-core" ; \
		mv shr-core/openembedded-core openembedded-core ; \
		ln -s ../openembedded-core shr-core/openembedded-core ; \
	fi
	if [ -d shr-core/meta-openembedded ] && [ ! -d meta-openembedded ] ; then \
		echo "Moving meta-openembedded checkout from shr-core" ; \
		mv shr-core/meta-openembedded meta-openembedded ; \
		ln -s ../meta-openembedded shr-core/meta-openembedded ; \
	fi 
	if [ -d shr-core/meta-smartphone ] && [ ! -d meta-smartphone ] ; then \
		echo "Moving meta-smartphone checkout from shr-core" ; \
		mv shr-core/meta-smartphone meta-smartphone ; \
		ln -s ../meta-smartphone shr-core/meta-smartphone ; \
	fi 
	[ ! -e openembedded-core ] || ${MAKE} update-openembedded-core
	[ ! -e meta-openembedded ] || ${MAKE} update-meta-openembedded
	[ ! -e meta-smartphone ]   || ${MAKE} update-meta-smartphone
	[ ! -e meta-browser ]      || ${MAKE} update-meta-browser
	[ ! -e bitbake ]      || ${MAKE} update-bitbake
	if [ -d shr-core ] ; then \
		if ! diff -q shr-core/conf/bblayers.conf common/conf/bblayers.conf ; then \
			echo -e "\\033[1;31m" "WARNING: you have different bblayers.conf, please sync it from common directory or call update-conffiles to replace all config files with new versions" ; \
			echo -e "\\e[0m" ; \
		fi ; \
	fi

.PHONY: status
status: status-common status-openembedded

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

.PHONY: setup-bitbake
.PRECIOUS: bitbake/.git/config
setup-bitbake bitbake/.git/config:
	[ -e bitbake/.git/config ] || \
	( echo "setting up bitbake ..."; \
	  git clone git://git.openembedded.org/bitbake bitbake; \
	  cd bitbake; \
	  git checkout ${BITBAKE_VERSION} 2>/dev/null || \
	  git checkout --no-track -b ${BITBAKE_VERSION} origin/${BITBAKE_VERSION} ; \
	  git reset --hard origin/${BITBAKE_VERSION} )

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

.PHONY: setup-openembedded-core
.PRECIOUS: openembedded-core/.git/config
setup-openembedded-core openembedded-core/.git/config:
	[ -e openembedded-core/.git/config ] || \
	( echo "setting up openembedded-core"; \
	  git clone ${URL_OE_CORE} openembedded-core )
	( cd openembedded-core && \
	  git checkout ${BRANCH_OE_CORE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_CORE} origin/${BRANCH_OE_CORE} )
	touch openembedded-core/.git/config

.PHONY: setup-meta-openembedded
.PRECIOUS: meta-openembedded/.git/config
setup-meta-openembedded meta-openembedded/.git/config:
	[ -e meta-openembedded/.git/config ] || \
	( echo "setting up meta-openembedded"; \
	  git clone ${URL_META_OE} meta-openembedded )
	( cd meta-openembedded && \
	  git checkout ${BRANCH_META_OE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_OE} origin/${BRANCH_META_OE} )
	touch meta-openembedded/.git/config

.PHONY: setup-meta-smartphone
.PRECIOUS: meta-smartphone/.git/config
setup-meta-smartphone meta-smartphone/.git/config:
	[ -e meta-smartphone/.git/config ] || \
	( echo "setting up meta-smartphone"; \
	  git clone ${URL_META_SMARTPHONE} meta-smartphone )
	( cd meta-smartphone && \
	  git checkout ${BRANCH_META_SMARTPHONE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_SMARTPHONE} origin/${BRANCH_META_SMARTPHONE} )
	touch meta-smartphone/.git/config

.PHONY: setup-meta-browser
.PRECIOUS: meta-browser/.git/config
setup-meta-browser meta-browser/.git/config:
	[ -e meta-browser/.git/config ] || \
	( echo "setting up meta-browser"; \
	  git clone ${URL_META_BROWSER} meta-browser )
	( cd meta-browser && \
	  git checkout ${BRANCH_META_BROWSER} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_BROWSER} origin/${BRANCH_META_BROWSER} )
	touch meta-browser/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured

.PRECIOUS: shr-core/.configured
shr-core/.configured: common/.git/config openembedded-core/.git/config meta-openembedded/.git/config meta-smartphone/.git/config meta-browser/.git/config
	@echo "preparing shr-core tree"
	[ -d shr-core ] || ( mkdir -p shr-core )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-core/openembedded-core ] || ( cd shr-core ; ln -sf ../openembedded-core . )
	[ -e shr-core/meta-openembedded ] || ( cd shr-core ; ln -sf ../meta-openembedded . )
	[ -e shr-core/meta-smartphone ] || ( cd shr-core ; ln -sf ../meta-smartphone . )
	[ -e shr-core/meta-browser ] || ( cd shr-core ; ln -sf ../meta-browser . )
	[ -e shr-core/setup-env ] || ( cd shr-core ; ln -sf ../common/setup-env . )
	[ -e shr-core/setup-local ] || ( cd shr-core ; cp ../common/setup-local . )
	[ -e shr-core/downloads ] || ( cd shr-core ; ln -sf ../downloads . )
	[ -e shr-core/bitbake ] || ( cd shr-core ; ln -sf ../bitbake . )
	[ -d shr-core/conf ] || ( cp -ra common/conf shr-core/conf )
	[ -e shr-core/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-core'" > shr-core/conf/topdir.conf
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

# shr branches in oe-core and meta-oe are rebased often
# so use shr_rebased_git_changelog.sh script if available

.PHONY: changelog-openembedded-core
changelog-openembedded-core: openembedded-core/.git/config
	@echo "Changelog for openembedded-core"
	( cd openembedded-core ; \
	  git remote update ; \
	  shr_rebased_git_changelog.sh `pwd` origin/${BRANCH_OE_CORE} ${URL_OE_CORE_UP} ${CHANGELOG_FORMAT} ${CHANGELOG_FORMAT_REBASE} 2>/dev/null || \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_OE_CORE} )

.PHONY: changelog-meta-openembedded
changelog-meta-openembedded: meta-openembedded/.git/config
	@echo "Changelog for meta-openembedded"
	( cd meta-openembedded ; \
	  git remote update ; \
	  shr_rebased_git_changelog.sh `pwd` origin/${BRANCH_META_OE} ${URL_META_OE_UP} ${CHANGELOG_FORMAT} ${CHANGELOG_FORMAT_REBASE} 2>/dev/null || \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_META_OE} )

.PHONY: changelog-meta-smartphone
changelog-meta-smartphone: meta-smartphone/.git/config
	@echo "Changelog for meta-smartphone"
	( cd meta-smartphone ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_META_SMARTPHONE} )

.PHONY: changelog-meta-browser
changelog-meta-browser: meta-browser/.git/config
	@echo "Changelog for meta-browser"
	( cd meta-browser ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BRANCH_META_BROWSER} )

.PHONY: changelog-bitbake
changelog-bitbake: bitbake/.git/config
	@echo "Changelog bitbake"
	( cd bitbake ; \
	  git remote update ; \
	  PAGER= git log --pretty=format:${CHANGELOG_FORMAT} ..origin/${BITBAKE_VERSION} )

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

.PHONY: update-bitbake
update-bitbake: bitbake/.git/config
	@echo "updating bitbake"
	( cd bitbake ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BITBAKE_VERSION} 2>/dev/null || \
	  git checkout --no-track -b ${BITBAKE_VERSION} origin/${BITBAKE_VERSION} ; \
	  git reset --hard origin/${BITBAKE_VERSION}; \
	)

.PHONY: update-openembedded-core
update-openembedded-core: openembedded-core/.git/config
	@echo "updating openembedded-core tree"
	( cd openembedded-core ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_CORE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_CORE} origin/${BRANCH_OE_CORE} ; \
	  git reset --hard origin/${BRANCH_OE_CORE} )

.PHONY: update-meta-openembedded
update-meta-openembedded: meta-openembedded/.git/config
	@echo "updating meta-openembedded tree"
	( cd meta-openembedded ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_META_OE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_OE} origin/${BRANCH_META_OE} ; \
	  git reset --hard origin/${BRANCH_META_OE} )

.PHONY: update-meta-smartphone
update-meta-smartphone: meta-smartphone/.git/config
	@echo "updating meta-smartphone tree"
	( cd meta-smartphone ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_META_SMARTPHONE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_SMARTPHONE} origin/${BRANCH_META_SMARTPHONE} ; \
	  git reset --hard origin/${BRANCH_META_SMARTPHONE} )

.PHONY: update-meta-browser
update-meta-browser: meta-browser/.git/config
	@echo "updating meta-browser tree"
	( cd meta-browser ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_META_BROWSER} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_BROWSER} origin/${BRANCH_META_BROWSER} ; \
	  git reset --hard origin/${BRANCH_META_BROWSER} )

update-conffiles: shr-core/.configured
	@echo "syncing shr-core config files up to date"
	cp common/conf/auto.conf shr-core/conf/auto.conf
	cp common/conf/bblayers.conf shr-core/conf/bblayers.conf
	cp common/conf/site.conf shr-core/conf/site.conf

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

# End of Makefile
