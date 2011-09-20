# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BITBAKE_VERSION = master
BRANCH_CHROOT = master
BRANCH_CHROOT_32BIT = 32bit
BRANCH_COMMON = master

BRANCH_OE = master
BRANCH_OE_SHR_UNSTABLE = master
BRANCH_OE_SHR_TESTING = shr/testing2011.1
BRANCH_OE_SHR_STABLE = shr/stable2009

BRANCH_OE_CORE = shr
BRANCH_META_OE = shr
BRANCH_META_SMARTPHONE = master

URL_OE = "git://github.com/openembedded/openembedded.git"
URL_OE_CORE = "git://git.openembedded.org/openembedded-core-contrib"
URL_SHR_MAKEFILE = "http://git.shr-project.org/repo/shr-makefile.git"
# use git://, because http:// transport doesn't support --depth
URL_SHR_CHROOT = "git://git.shr-project.org/shr-chroot.git"
URL_META_SMARTPHONE = "git://git.shr-project.org/meta-smartphone.git"
URL_META_OE = "git://git.openembedded.org/meta-openembedded-contrib"

.PHONY: all
all: update build

.PHONY: update
update: 
#       don't update shr-chroot automatically, let user to umount all binds
#	[ ! -e ../.git/config-32bit ] || ${MAKE} update-shr-chroot-32bit 
#	[ ! -e ../.git/config-64bit ] || ${MAKE} update-shr-chroot 
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
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e openembedded-core ] || ${MAKE} update-openembedded-core
	[ ! -e meta-openembedded ] || ${MAKE} update-meta-openembedded
	[ ! -e meta-smartphone ]   || ${MAKE} update-meta-smartphone
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e shr-testing ]  || ${MAKE} update-shr-testing
	[ ! -e bitbake ]      || ${MAKE} update-bitbake
	if [ -d shr-core ] ; then \
		if ! diff -q shr-core/conf/bblayers.conf common/conf/shr-core/bblayers.conf ; then \
			echo -e "\\033[1;31m" "WARNING: you have different bblayers.conf, please sync it from common directory or call update-shr-core-conffiles to replace all config files with new versions" ; \
			echo -e "\\e[0m" ; \
		fi ; \
	fi
	if [ -d aurora ] ; then \
		if ! diff -q aurora/conf/bblayers.conf common/conf/aurora/bblayers.conf ; then \
			echo -e "\\033[1;31m" "WARNING: you have different bblayers.conf, please sync it from common directory or call update-aurora-conffiles to replace all config files with new versions" ; \
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

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config:
	[ -e openembedded/.git/config ] || \
	( echo "setting up openembedded"; \
	  git clone ${URL_OE} openembedded )
	( cd openembedded && \
	  git checkout ${BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE} origin/${BRANCH_OE} )
	touch openembedded/.git/config

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


.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured


.PRECIOUS: shr-testing/.configured
shr-testing/.configured: common/.git/config openembedded/.git/config
	@echo "preparing shr-testing tree"
	[ -d shr-testing ] || ( mkdir -p shr-testing )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-testing/setup-env ] || ( cd shr-testing ; ln -sf ../common/setup-env . )
	[ -e shr-testing/setup-local ] || ( cd shr-testing ; cp ../common/setup-local . )
	[ -e shr-testing/downloads ] || ( cd shr-testing ; ln -sf ../downloads . )
	[ -e shr-testing/openembedded ] || ( cd shr-testing ; \
	  git clone --reference ../openembedded ${URL_OE} openembedded; \
	  cd openembedded ; \
	  echo "replace git object reference with relative path" ; \
	  echo "../../../../openembedded/.git/objects/" > .git/objects/info/alternates ; \
	  git checkout ${BRANCH_OE_SHR_TESTING} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_TESTING} origin/${BRANCH_OE_SHR_TESTING} )
	[ -d shr-testing/conf ] || ( mkdir -p shr-testing/conf )
	[ -e shr-testing/conf/site.conf ] || ( cd shr-testing/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-testing/conf/auto.conf ] || ( cp common/conf/auto.conf shr-testing/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-testing2011.1/ipk/\"" >> shr-testing/conf/auto.conf ; \
	)
	[ -e shr-testing/conf/local.conf ] || ( cp common/conf/local.conf shr-testing/conf/local.conf )
	[ -e shr-testing/conf/local-builds.inc ] || ( cp common/conf/local-builds.inc shr-testing/conf/local-builds.inc )
	[ -e shr-testing/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-testing'" > shr-testing/conf/topdir.conf
	touch shr-testing/.configured
	
.PRECIOUS: shr-unstable/.configured
shr-unstable/.configured: common/.git/config openembedded/.git/config
	@echo "preparing shr-unstable tree"
	[ -d shr-unstable ] || ( mkdir -p shr-unstable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-unstable/setup-env ] || ( cd shr-unstable ; ln -sf ../common/setup-env . )
	[ -e shr-unstable/setup-local ] || ( cd shr-unstable ; cp ../common/setup-local . )
	[ -e shr-unstable/downloads ] || ( cd shr-unstable ; ln -sf ../downloads . )
	[ -e shr-unstable/openembedded ] || ( cd shr-unstable ; \
	  git clone --reference ../openembedded ${URL_OE} openembedded; \
	  cd openembedded ; \
	  echo "replace git object reference with relative path" ; \
	  echo "../../../../openembedded/.git/objects/" > .git/objects/info/alternates ; \
	  git checkout ${BRANCH_OE_SHR_UNSTABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_UNSTABLE} origin/${BRANCH_OE_SHR_UNSTABLE} )
	[ -d shr-unstable/conf ] || ( mkdir -p shr-unstable/conf )
	[ -e shr-unstable/conf/site.conf ] || ( cd shr-unstable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-unstable/conf/auto.conf ] || ( cp common/conf/auto.conf shr-unstable/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-unstable/ipk/\"" >> shr-unstable/conf/auto.conf ; \
	)
	[ -e shr-unstable/conf/local.conf ] || ( cp common/conf/local.conf shr-unstable/conf/local.conf; \
	  echo "# shr-autorev.inc is no longer supported by SHR devs for shr-unstable" >> shr-unstable/conf/local.conf ; \
	  echo "# so it's possible that newer revisions will need also newer EFL then what's available in shr-unstable" >> shr-unstable/conf/local.conf ; \
	  echo "# if you need newer SHR apps or EFL, use shr-core" >> shr-unstable/conf/local.conf ; \
	  echo "#require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
	)
	[ -e shr-unstable/conf/local-builds.inc ] || ( cp common/conf/local-builds.inc shr-unstable/conf/local-builds.inc; )
	[ -e shr-unstable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-unstable'" > shr-unstable/conf/topdir.conf
	touch shr-unstable/.configured
	
.PRECIOUS: shr-core/.configured
shr-core/.configured: common/.git/config openembedded-core/.git/config meta-openembedded/.git/config meta-smartphone/.git/config
	@echo "preparing shr-core tree"
	[ -d shr-core ] || ( mkdir -p shr-core )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-core/openembedded-core ] || ( cd shr-core ; ln -sf ../openembedded-core . )
	[ -e shr-core/meta-openembedded ] || ( cd shr-core ; ln -sf ../meta-openembedded . )
	[ -e shr-core/meta-smartphone ] || ( cd shr-core ; ln -sf ../meta-smartphone . )
	[ -e shr-core/setup-env ] || ( cd shr-core ; ln -sf ../common/setup-env . )
	[ -e shr-core/setup-local ] || ( cd shr-core ; cp ../common/setup-local .; echo 'export BBFETCH2=True' >> setup-local )
	[ -e shr-core/downloads ] || ( cd shr-core ; ln -sf ../downloads . )
	[ -e shr-core/bitbake ] || ( cd shr-core ; ln -sf ../bitbake . )
	[ -d shr-core/conf ] || ( cp -ra common/conf/shr-core shr-core/conf )
	[ -e shr-core/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-core'" > shr-core/conf/topdir.conf
	touch shr-core/.configured

.PRECIOUS: aurora/.configured
aurora/.configured: common/.git/config openembedded-core/.git/config meta-openembedded/.git/config meta-smartphone/.git/config
	@echo "preparing aurora tree"
	[ -d aurora ] || ( mkdir -p aurora )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e aurora/openembedded-core ] || ( cd aurora ; ln -sf ../openembedded-core . )
	[ -e aurora/meta-openembedded ] || ( cd aurora ; ln -sf ../meta-openembedded . )
	[ -e aurora/meta-smartphone ] || ( cd aurora ; ln -sf ../meta-smartphone . )
	[ -e aurora/setup-env ] || ( cd aurora ; ln -sf ../common/setup-env . )
	[ -e aurora/setup-local ] || ( cd aurora ; \
	  echo "# keep this file compatible with sh (it's read from setup-env)" > setup-local; \
	  echo "DISTRO="aurora"" >> setup-local; \
	  echo "MACHINE="palmpre2"" >> setup-local; \
	  echo "export BBFETCH2=True" >> setup-local; )
	[ -e aurora/downloads ] || ( cd aurora ; ln -sf ../downloads . )
	[ -e aurora/bitbake ] || ( cd aurora ; ln -sf ../bitbake . )
	[ -d aurora/conf ] || ( cp -ra common/conf/aurora aurora/conf )
	[ -e aurora/conf/topdir.conf ] || echo "TOPDIR='`pwd`/aurora'" > aurora/conf/topdir.conf
	touch aurora/.configured

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

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	@echo "updating openembedded"
	( cd openembedded ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git pull || ( \
	  echo ; \
	  echo "!!! looks like either the OE git server has problems"; \
	  echo "or you have a dirty OE tree ;)"; \
	  echo "to fix that do the following:"; \
	  echo "cd `pwd`; git reset --hard"; \
	  echo ; \
	  echo "ATTENTION: that will kill all eventual changes" ) )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	@echo "updating shr-testing tree"
	( cd shr-testing/openembedded ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_SHR_TESTING} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_TESTING} origin/${BRANCH_OE_SHR_TESTING} ; \
	  git reset --hard origin/${BRANCH_OE_SHR_TESTING} )

.PHONY: update-shr-unstable
update-shr-unstable: shr-unstable/.configured
	@echo "updating shr-unstable tree"
	( cd shr-unstable/openembedded ; \
	  sed -e s/git.openembedded.net/git.openembedded.org/ -i .git/config ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_SHR_UNSTABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_UNSTABLE} origin/${BRANCH_OE_SHR_UNSTABLE} ; \
	  git reset --hard origin/${BRANCH_OE_SHR_UNSTABLE} )

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

update-shr-core-conffiles: shr-core/.configured
	@echo "syncing shr-core config files up to date"
	cp common/conf/shr-core/auto.conf shr-core/conf/auto.conf
	cp common/conf/shr-core/bblayers.conf shr-core/conf/bblayers.conf
	cp common/conf/shr-core/site.conf shr-core/conf/site.conf

update-aurora-conffiles: aurora/.configured
	@echo "syncing aurora config files up to date"
	cp common/conf/aurora/auto.conf aurora/conf/auto.conf
	cp common/conf/aurora/bblayers.conf aurora/conf/bblayers.conf
	cp common/conf/aurora/site.conf aurora/conf/site.conf

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

# End of Makefile
