# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BITBAKE_VERSION = 1.12
BRANCH_CHROOT = master
BRANCH_CHROOT_32BIT = 32bit
BRANCH_COMMON = master

BRANCH_OE = master
BRANCH_OE_SHR_UNSTABLE = master
BRANCH_OE_SHR_TESTING = shr/testing2011.1
BRANCH_OE_SHR_STABLE = shr/stable2009

BRANCH_OE_CORE = shr
BRANCH_META_OE = shr
BRANCH_META_SHR = master

URL_OE = "git://git.openembedded.net/openembedded"
URL_OE_CORE = "git://git.openembedded.net/openembedded-core-core"
URL_SHR_MAKEFILE = "http://git.shr-project.org/repo/shr-makefile.git"
# use git://, because http:// transport doesn't support --depth
URL_SHR_CHROOT = "git://git.shr-project.org/shr-chroot.git"
URL_META_SHR = "git://git.shr-project.org/meta-shr.git"
URL_META_OE = "git://git.openembedded.net/meta-openembedded-contrib"

.PHONY: all
all: update build

.PHONY: update
update: 
	[ ! -e ../.git/config-32bit ] || ${MAKE} update-shr-chroot-32bit 
	[ ! -e ../.git/config-64bit ] || ${MAKE} update-shr-chroot 
	[ ! -e common ]       || ${MAKE} update-common 
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e shr-core/openembedded-core ] || ${MAKE} update-shr-core-openembedded-core
	[ ! -e shr-core/meta-openembedded ] || ${MAKE} update-shr-core-meta-openembedded
	[ ! -e shr-core/meta-shr ]          || ${MAKE} update-shr-core-meta-shr
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e shr-testing ]  || ${MAKE} update-shr-testing 
	[ ! -e shr-stable ]   || ${MAKE} update-shr-stable
	[ ! -e bitbake ]      || ${MAKE} update-bitbake

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
	  git clone git://git.openembedded.net/bitbake bitbake; \
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

.PHONY: setup-shr-core-openembedded-core
.PRECIOUS: shr-core/openembedded-core/.git/config
setup-shr-core-openembedded-core shr-core/openembedded-core/.git/config:
	[ -e shr-core/openembedded-core/.git/config ] || \
	( echo "setting up openembedded-core"; \
	  git clone ${URL_OE_CORE} shr-core/openembedded-core )
	( cd shr-core/openembedded-core && \
	  git checkout ${BRANCH_OE_CORE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_CORE} origin/${BRANCH_OE_CORE} )
	touch shr-core/openembedded-core/.git/config

.PHONY: setup-shr-core-meta-openembedded
.PRECIOUS: shr-core/meta-openembedded/.git/config
setup-shr-core-meta-openembedded shr-core/meta-openembedded/.git/config:
	[ -e shr-core/meta-openembedded/.git/config ] || \
	( echo "setting up meta-openembedded"; \
	  git clone ${URL_META_OE} shr-core/meta-openembedded )
	( cd shr-core/meta-openembedded && \
	  git checkout ${BRANCH_META_OE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_OE} origin/${BRANCH_META_OE} )
	touch shr-core/meta-openembedded/.git/config

.PHONY: setup-shr-core-meta-shr
.PRECIOUS: shr-core/meta-shr/.git/config
setup-shr-core-meta-shr shr-core/meta-shr/.git/config:
	[ -e shr-core/meta-shr/.git/config ] || \
	( echo "setting up meta-shr"; \
	  git clone ${URL_META_SHR} shr-core/meta-shr )
	( cd shr-core/meta-shr && \
	  git checkout ${BRANCH_META_SHR} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_SHR} origin/${BRANCH_META_SHR} )
	touch shr-core/meta-shr/.git/config


.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured


##.PRECIOUS: shr-stable/.configured
shr-stable/.configured: common/.git/config openembedded/.git/config
	@echo "preparing shr-stable tree"
	[ -d shr-stable ] || ( mkdir -p shr-stable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-stable/setup-env ] || ( cd shr-stable ; ln -sf ../common/setup-env . )
	[ -e shr-stable/setup-local ] || ( cd shr-stable ; cp ../common/setup-local . )
	[ -e shr-stable/downloads ] || ( cd shr-stable ; ln -sf ../downloads . )
	[ -e shr-stable/openembedded ] || ( cd shr-stable ; \
	  git clone --reference ../openembedded ${URL_OE} openembedded; \
	  cd openembedded ; \
	  git checkout ${BRANCH_OE_SHR_STABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_STABLE} origin/${BRANCH_OE_SHR_STABLE} )
	[ -d shr-stable/conf ] || ( mkdir -p shr-stable/conf )
	[ -e shr-stable/conf/site.conf ] || ( cd shr-stable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-stable/conf/auto.conf ] || ( cp common/conf/auto.conf shr-stable/conf/auto.conf; \
		echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-stable/ipk/\"" >> shr-stable/conf/auto.conf ; \
	)
	[ -e shr-stable/conf/local.conf ] || ( cp common/conf/local.conf shr-stable/conf/local.conf )
	[ -e shr-stable/conf/local-builds.inc ] || ( cp common/conf/local-builds.inc shr-stable/conf/local-builds.inc )
	[ -e shr-stable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-stable'" > shr-stable/conf/topdir.conf
	touch shr-stable/.configured

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
	  git checkout ${BRANCH_OE_SHR_UNSTABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_UNSTABLE} origin/${BRANCH_OE_SHR_UNSTABLE} )
	[ -d shr-unstable/conf ] || ( mkdir -p shr-unstable/conf )
	[ -e shr-unstable/conf/site.conf ] || ( cd shr-unstable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-unstable/conf/auto.conf ] || ( cp common/conf/auto.conf shr-unstable/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-unstable/ipk/\"" >> shr-unstable/conf/auto.conf ; \
	)
	[ -e shr-unstable/conf/local.conf ] || ( cp common/conf/local.conf shr-unstable/conf/local.conf; \
	  echo "require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
	)
	[ -e shr-unstable/conf/local-builds.inc ] || ( cp common/conf/local-builds.inc shr-unstable/conf/local-builds.inc; )
	[ -e shr-unstable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-unstable'" > shr-unstable/conf/topdir.conf
	touch shr-unstable/.configured
	
.PRECIOUS: shr-core/.configured
shr-core/.configured: common/.git/config shr-core/openembedded-core/.git/config shr-core/meta-openembedded/.git/config shr-core/meta-shr/.git/config
	@echo "preparing shr-core tree"
	[ -d shr-core ] || ( mkdir -p shr-core )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-core/setup-env ] || ( cd shr-core ; ln -sf ../common/setup-env . )
	[ -e shr-core/setup-local ] || ( cd shr-core ; cp ../common/setup-local .; echo 'export BBFETCH2=True' >> setup-local )
	[ -e shr-core/downloads ] || ( cd shr-core ; ln -sf ../downloads . )
	[ -d shr-core/conf ] || ( cp -ra common/conf/shr-core shr-core/conf )
	[ -e shr-core/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-core'" > shr-core/conf/topdir.conf
	touch shr-core/.configured

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
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BITBAKE_VERSION} 2>/dev/null || \
	  git checkout --no-track -b ${BITBAKE_VERSION} origin/${BITBAKE_VERSION} ; \
	  git reset --hard origin/${BITBAKE_VERSION}; \
	)

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	@echo "updating openembedded"
	( cd openembedded ; git pull || ( \
	  echo ; \
	  echo "!!! looks like either the OE git server has problems"; \
	  echo "or you have a dirty OE tree ;)"; \
	  echo "to fix that do the following:"; \
	  echo "cd `pwd`; git reset --hard"; \
	  echo ; \
	  echo "ATTENTION: that will kill all eventual changes" ) )

.PHONY: update-shr-stable
update-shr-stable: shr-stable/.configured
	@echo "updating shr-stable tree"
	( cd shr-stable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_SHR_STABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_STABLE} origin/${BRANCH_OE_SHR_STABLE} ; \
	  git reset --hard origin/${BRANCH_OE_SHR_STABLE} )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	@echo "updating shr-testing tree"
	( cd shr-testing/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_SHR_TESTING} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_TESTING} origin/${BRANCH_OE_SHR_TESTING} ; \
	  git reset --hard origin/${BRANCH_OE_SHR_TESTING} )

.PHONY: update-shr-unstable
update-shr-unstable: shr-unstable/.configured
	@echo "updating shr-unstable tree"
	( cd shr-unstable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_SHR_UNSTABLE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_SHR_UNSTABLE} origin/${BRANCH_OE_SHR_UNSTABLE} ; \
	  git reset --hard origin/${BRANCH_OE_SHR_UNSTABLE} )

.PHONY: update-shr-core-openembedded-core
update-shr-core-openembedded-core: shr-core/openembedded-core/.git/config
	@echo "updating shr-core/openembedded-core tree"
	( cd shr-core/openembedded-core ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_OE_CORE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_OE_CORE} origin/${BRANCH_OE_CORE} ; \
	  git reset --hard origin/${BRANCH_OE_CORE} )

.PHONY: update-shr-core-meta-openembedded
update-shr-core-meta-openembedded: shr-core/meta-openembedded/.git/config
	@echo "updating shr-core/meta-openembedded tree"
	( cd shr-core/meta-openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_META_OE} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_OE} origin/${BRANCH_META_OE} ; \
	  git reset --hard origin/${BRANCH_META_OE} )

.PHONY: update-shr-core-meta-shr
update-shr-core-meta-shr: shr-core/meta-shr/.git/config
	@echo "updating shr-core/meta-shr tree"
	( cd shr-core/meta-shr ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${BRANCH_META_SHR} 2>/dev/null || \
	  git checkout --no-track -b ${BRANCH_META_SHR} origin/${BRANCH_META_SHR} ; \
	  git reset --hard origin/${BRANCH_META_SHR} )

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

# End of Makefile
