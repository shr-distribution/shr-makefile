# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

CHROOT_BRANCH = master

BRANCH_OE = master
SHR_UNSTABLE_BRANCH_OE = master
SHR_TESTING_BRANCH_OE = shr/testing2011.1
SHR_STABLE_BRANCH_OE = shr/stable2009

SHR_MAKEFILE_URL = "http://git.shr-project.org/repo/shr-makefile.git"
SHR_CHROOT_URL = "http://git.shr-project.org/repo/shr-chroot.git"

.PHONY: all
all: update build

.PHONY: setup
setup: setup-shr-chroot setup-common setup-openembedded setup-shr-unstable setup-shr-testing 
#setup-shr-stable

.PHONY: update
update: 
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	${MAKE} update-shr-chroot 
	[ ! -e /OE/common ]       || ${MAKE} update-common 
	[ ! -e /OE/openembedded ] || ${MAKE} update-openembedded 
	[ ! -e /OE/shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e /OE/shr-testing ]  || ${MAKE} update-shr-testing 
##	[ ! -e /OE/shr-stable ]   || ${MAKE} update-shr-stable

.PHONY: status
status: status-chroot status-common status-openembedded

.PHONY: setup-shr-chroot
.PRECIOUS: shr-chroot/.git/config
setup-shr-chroot shr-chroot/.git/config:
	[ ! -e /OE/.keep ] || \
	( echo "You're already in shr-chroot (/OE/.keep exists)"; \
	  exit 1; \
	)
	[ -e shr-chroot/.git/config ] || \
	( echo "setting up shr-chroot ..."; \
	  git clone ${SHR_CHROOT_URL} shr-chroot; \
	  cd shr-chroot; \
	  git checkout ${CHROOT_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH} origin/${CHROOT_BRANCH} ; \
	  git reset --hard origin/${CHROOT_BRANCH}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash/#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash/#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)
	mv Makefile shr-chroot/OE/Makefile
	touch shr-chroot/.git/config
	echo "Now run shr-chroot.sh in shr-chroot as ROOT to switch to new SHR chroot environment"

.PHONY: setup-common
.PRECIOUS: /OE/common/.git/config
setup-common /OE/common/.git/config:
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	[ -e /OE/common/.git/config ] || \
	( echo "setting up /OE/common (Makefile)"; \
	  git clone ${SHR_MAKEFILE_URL} /OE/common && \
	  rm -f Makefile && \
	  ln -s /OE/common/Makefile Makefile )
	touch /OE/common/.git/config

.PHONY: setup-openembedded
.PRECIOUS: /OE/openembedded/.git/config
setup-openembedded /OE/openembedded/.git/config:
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	[ -e /OE/openembedded/.git/config ] || \
	( echo "setting up /OE/openembedded"; \
	  git clone git://git.openembedded.net/openembedded /OE/openembedded )
	( cd /OE/openembedded && \
	  git checkout ${OE_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${OE_BRANCH} origin/${OE_BRANCH} )
	touch /OE/openembedded/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} /OE/$*/.configured


##.PRECIOUS: /OE/shr-stable/.configured
/OE/shr-stable/.configured: /OE/common/.git/config /OE/openembedded/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "preparing /OE/shr-stable tree"
	[ -d /OE/shr-stable ] || ( mkdir -p /OE/shr-stable )
	[ -e /OE/downloads ] || ( mkdir -p /OE/downloads )
	[ -e /OE/shr-stable/setup-env ] || ( cd /OE/shr-stable ; ln -sf ../common/setup-env . )
	[ -e /OE/shr-stable/downloads ] || ( cd /OE/shr-stable ; ln -sf ../downloads . )
	[ -e /OE/shr-stable/openembedded ] || ( cd /OE/shr-stable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} )
	[ -d /OE/shr-stable/conf ] || ( mkdir -p /OE/shr-stable/conf )
	[ -e /OE/shr-stable/conf/site.conf ] || ( cd /OE/shr-stable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e /OE/shr-stable/conf/auto.conf ] || ( cp /OE/common/conf/auto.conf /OE/shr-stable/conf/auto.conf; \
		echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-stable/ipk/\"" >> /OE/shr-stable/conf/auto.conf ; \
	)
	[ -e /OE/shr-stable/conf/local.conf ] || ( cp /OE/common/conf/local.conf /OE/shr-stable/conf/local.conf )
	[ -e /OE/shr-stable/conf/local-builds.inc ] || ( cp /OE/common/conf/local-builds.inc /OE/shr-stable/conf/local-builds.inc )
	[ -e /OE/shr-stable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-stable'" > shr-stable/conf/topdir.conf
	touch shr-stable/.configured

.PRECIOUS: /OE/shr-testing/.configured
/OE/shr-testing/.configured: /OE/common/.git/config /OE/openembedded/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "preparing /OE/shr-testing tree"
	[ -d /OE/shr-testing ] || ( mkdir -p /OE/shr-testing )
	[ -e /OE/downloads ] || ( mkdir -p /OE/downloads )
	[ -e /OE/shr-testing/setup-env ] || ( cd /OE/shr-testing ; ln -sf ../common/setup-env . )
	[ -e /OE/shr-testing/downloads ] || ( cd /OE/shr-testing ; ln -sf ../downloads . )
	[ -e /OE/shr-testing/openembedded ] || ( cd /OE/shr-testing ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} )
	[ -d /OE/shr-testing/conf ] || ( mkdir -p /OE/shr-testing/conf )
	[ -e /OE/shr-testing/conf/site.conf ] || ( cd /OE/shr-testing/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e /OE/shr-testing/conf/auto.conf ] || ( cp /OE/common/conf/auto.conf /OE/shr-testing/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-testing/ipk/\"" >> /OE/shr-testing/conf/auto.conf ; \
	)
	[ -e /OE/shr-testing/conf/local.conf ] || ( cp /OE/common/conf/local.conf /OE/shr-testing/conf/local.conf )
	[ -e /OE/shr-testing/conf/local-builds.inc ] || ( cp /OE/common/conf/local-builds.inc /OE/shr-testing/conf/local-builds.inc )
	[ -e /OE/shr-testing/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-testing'" > shr-testing/conf/topdir.conf
	touch shr-testing/.configured
	
.PRECIOUS: /OE/shr-unstable/.configured
/OE/shr-unstable/.configured: /OE/common/.git/config /OE/openembedded/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "preparing shr-unstable tree"
	[ -d /OE/shr-unstable ] || ( mkdir -p /OE/shr-unstable )
	[ -e /OE/downloads ] || ( mkdir -p /OE/downloads )
	[ -e /OE/shr-unstable/setup-env ] || ( cd /OE/shr-unstable ; ln -sf ../common/setup-env . )
	[ -e /OE/shr-unstable/downloads ] || ( cd /OE/shr-unstable ; ln -sf ../downloads . )
	[ -e /OE/shr-unstable/openembedded ] || ( cd /OE/shr-unstable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} )
	[ -d /OE/shr-unstable/conf ] || ( mkdir -p /OE/shr-unstable/conf )
	[ -e /OE/shr-unstable/conf/site.conf ] || ( cd /OE/shr-unstable/conf ; ln -sf ../../common/conf/site.conf ./site.conf )
	[ -e /OE/shr-unstable/conf/auto.conf ] || ( cp /OE/common/conf/auto.conf /OE/shr-unstable/conf/auto.conf; \
	  echo "DISTRO_FEED_URI=\"http://build.shr-project.org/shr-unstable/ipk/\"" >> /OE/shr-unstable/conf/auto.conf ; \
	)
	[ -e /OE/shr-unstable/conf/local.conf ] || ( cp /OE/common/conf/local.conf /OE/shr-unstable/conf/local.conf; \
	  echo "require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
	)
	[ -e /OE/shr-unstable/conf/local-builds.inc ] || ( cp /OE/common/conf/local-builds.inc /OE/shr-unstable/conf/local-builds.inc; )
	[ -e /OE/shr-unstable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-unstable'" > shr-unstable/conf/topdir.conf
	touch shr-unstable/.configured
	
.PHONY: update-common
update-common: /OE/common/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating /OE/common (Makefile)"
	( cd /OE/common ; git pull )

.PHONY: update-shr-chroot
update-shr-chroot: /.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating shr-chroot"
	( cd /; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${CHROOT_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH} origin/${CHROOT_BRANCH} ; \
	  git reset --hard origin/${CHROOT_BRANCH}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash/#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash/#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
	)

.PHONY: update-openembedded
update-openembedded: /OE/openembedded/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating /OE/openembedded"
	( cd /OE/openembedded ; git pull || ( \
	  echo ; \
	  echo "!!! looks like either the OE git server has problems"; \
	  echo "or you have a dirty OE tree ;)"; \
	  echo "to fix that do the following:"; \
	  echo "cd `pwd`; git reset --hard"; \
	  echo ; \
	  echo "ATTENTION: that will kill all eventual changes" ) )

.PHONY: update-shr-stable
update-shr-stable: shr-stable/.configured
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating /OE/shr-stable tree"
	( cd /OE/shr-stable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_STABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_STABLE_BRANCH_OE} origin/${SHR_STABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_STABLE_BRANCH_OE} )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating /OE/shr-testing tree"
	( cd /OE/shr-testing/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_TESTING_BRANCH_OE} )

.PHONY: update-shr-unstable
update-shr-unstable: /OE/shr-unstable/.configured
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	@echo "updating /OE/shr-unstable tree"
	( cd /OE/shr-unstable/openembedded ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} 2>/dev/null || \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE} ; \
	  git reset --hard origin/${SHR_UNSTABLE_BRANCH_OE} )

.PHONY: status-common
status-common: /OE/common/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	( cd /OE/common ; git diff --stat )

.PHONY: status-openembedded
status-openembedded: /OE/openembedded/.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	( cd /OE/openembedded ; git diff --stat )

.PHONY: status-shr-chroot
status-shr-chroot: /.git/config
	[ -e /OE/.keep ] || \
	( echo "You're not in shr-chroot, use shr-chroot.sh first."; \
	  exit 1; \
	)
	( cd /; git diff --stat )

# End of Makefile
