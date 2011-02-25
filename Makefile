# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

BITBAKE_VERSION = 1.10
CHROOT_BRANCH = master
CHROOT_BRANCH_32BIT = 32bit
COMMON_BRANCH = shr-chroot

BRANCH_OE = master
SHR_UNSTABLE_BRANCH_OE = master
SHR_TESTING_BRANCH_OE = shr/testing2011.1
SHR_STABLE_BRANCH_OE = shr/stable2009

SHR_MAKEFILE_URL = "http://git.shr-project.org/repo/shr-makefile.git"
SHR_CHROOT_URL = "http://git.shr-project.org/repo/shr-chroot.git"

.PHONY: all
all: update build

.PHONY: update
update: 
	[ ! -e ../OE/lib64 ]  || ${MAKE} update-shr-chroot 
	[ ! -e ../OE ]        || ${MAKE} update-shr-chroot-32bit 
	[ ! -e common ]       || ${MAKE} update-common 
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e shr-testing ]  || ${MAKE} update-shr-testing 
	[ ! -e shr-stable ]   || ${MAKE} update-shr-stable
	[ ! -e bitbake ]      || ${MAKE} update-bitbake

.PHONY: status
status: status-common status-openembedded

.PHONY: setup-shr-chroot
.PRECIOUS: shr-chroot/.git/config
setup-shr-chroot shr-chroot/.git/config:
	[ -e shr-chroot/.git/config ] || \
	( echo "setting up shr-chroot ..."; \
	  git clone --depth 1 ${SHR_CHROOT_URL} shr-chroot; \
	  cd shr-chroot; \
	  git checkout ${CHROOT_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH} origin/${CHROOT_BRANCH} ; \
	  git reset --hard origin/${CHROOT_BRANCH}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)
	mv Makefile shr-chroot/OE/Makefile
	touch shr-chroot/.git/config
	echo "Now run shr-chroot.sh in shr-chroot as ROOT to switch to new SHR chroot environment"

.PHONY: setup-shr-chroot-32bit
.PRECIOUS: shr-chroot/.git/config
setup-shr-chroot-32bit shr-chroot/.git/config:
	[ -e shr-chroot/.git/config ] || \
	( echo "setting up 32bit shr-chroot ..."; \
	  git clone --depth 1 ${SHR_CHROOT_URL} shr-chroot; \
	  cd shr-chroot; \
	  git checkout ${CHROOT_BRANCH_32BIT} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH_32BIT} origin/${CHROOT_BRANCH_32BIT} ; \
	  git reset --hard origin/${CHROOT_BRANCH_32BIT}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)
	mv Makefile shr-chroot/OE/Makefile
	touch shr-chroot/.git/config
	echo "Now run shr-chroot.sh in shr-chroot as ROOT to switch to new SHR chroot environment"

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
	  git clone ${SHR_MAKEFILE_URL} common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	( cd common && \
	  git checkout ${COMMON_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${COMMON_BRANCH} origin/${COMMON_BRANCH} )
	touch common/.git/config

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config:
	[ -e openembedded/.git/config ] || \
	( echo "setting up openembedded"; \
	  git clone git://git.openembedded.net/openembedded openembedded )
	( cd openembedded && \
	  git checkout ${OE_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${OE_BRANCH} origin/${OE_BRANCH} )
	touch openembedded/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured


##.PRECIOUS: shr-stable/.configured
shr-stable/.configured: common/.git/config openembedded/.git/config
	@echo "preparing shr-stable tree"
	[ -d shr-stable ] || ( mkdir -p shr-stable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-stable/setup-env ] || ( cd shr-stable ; ln -sf ../common/setup-env . )
	[ -e shr-stable/downloads ] || ( cd shr-stable ; ln -sf ../downloads . )
	[ -e shr-stable/openembedded ] || ( cd shr-stable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} )
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
	[ -e shr-testing/downloads ] || ( cd shr-testing ; ln -sf ../downloads . )
	[ -e shr-testing/openembedded ] || ( cd shr-testing ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} )
	[ -d shr-testing/conf ] || ( mkdir -p shr-testing/conf )
	[ -e shr-testing/conf/site.conf ] || ( cd shr-testing/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e shr-testing/conf/auto.conf ] || ( cp common/conf/auto.conf shr-testing/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-testing/ipk/\"" >> shr-testing/conf/auto.conf ; \
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
	[ -e shr-unstable/downloads ] || ( cd shr-unstable ; ln -sf ../downloads . )
	[ -e shr-unstable/openembedded ] || ( cd shr-unstable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} )
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
	
.PHONY: update-common
update-common: common/.git/config
	@echo "updating common (Makefile)"
	( cd common ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${COMMON_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${COMMON_BRANCH} origin/${COMMON_BRANCH} ; \
	  git reset --hard origin/${COMMON_BRANCH}
	)

.PHONY: update-shr-chroot
update-shr-chroot: ../.git/config
	@echo "updating shr-chroot"
	[ -d ../OE ] || ( echo "There should be ../OE if you have shr-chroot" && exit 1 )
	( cd .. ; \
	  git fetch ; \
	  git checkout ${CHROOT_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH} origin/${CHROOT_BRANCH} ; \
	  git reset --hard origin/${CHROOT_BRANCH}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)

.PHONY: update-shr-chroot-32bit
update-shr-chroot-32bit: ../.git/config
	@echo "updating 32bit shr-chroot"
	[ -d ../OE ] || ( echo "There should be ../OE if you have shr-chroot" && exit 1 )
	( cd .. ; \
	  git fetch ; \
	  git checkout ${CHROOT_BRANCH_32BIT} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH_32BIT} origin/${CHROOT_BRANCH_32BIT} ; \
	  git reset --hard origin/${CHROOT_BRANCH_32BIT}; \
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
	  git reset --hard origin/${BITBAKE_VERSION}
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
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_STABLE_BRANCH_OE} )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	@echo "updating shr-testing tree"
	( cd shr-testing/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_TESTING_BRANCH_OE} )

.PHONY: update-shr-unstable
update-shr-unstable: shr-unstable/.configured
	@echo "updating shr-unstable tree"
	( cd shr-unstable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_UNSTABLE_BRANCH_OE} )

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

# End of Makefile
