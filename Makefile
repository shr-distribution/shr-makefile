# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

MAKEFLAGS = -swr

CHROOT_BRANCH = master

SHR_TESTING_BRANCH_OE = shr/testing2011.1
SHR_UNSTABLE_BRANCH_OE = org.openembedded.dev
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
	[ ! -e shr-chroot ] || ${MAKE} update-shr-chroot 
	[ ! -e common ] || ${MAKE} update-common 
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable
	[ ! -e shr-testing ] || ${MAKE} update-shr-testing 
##	[ ! -e shr-stable ] || ${MAKE} update-shr-stable

.PHONY: status
status: status-chroot status-common status-openembedded

.PHONY: setup-common
.PRECIOUS: common/.git/config
setup-common common/.git/config:
	[ -e common/.git/config ] || \
	( echo "setting up common (Makefile)"; \
	  git clone ${SHR_MAKEFILE_URL} common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	touch common/.git/config

.PHONY: setup-shr-chroot
.PRECIOUS: shr-chroot/.git/config
setup-shr-chroot shr-chroot/.git/config:
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
	[ -e shr-chroot.sh ] || ( \
	  echo "# Use this script to setup chroot environment for building SHR" >> shr-chroot.sh \
	  echo "cd shr-chroot" >> shr-chroot.sh ; \
	  echo "chmod 1777 /dev/shm" >> shr-chroot.sh ; \
	  echo "mount -o bind /dev/ dev" >> shr-chroot.sh ; \
	  echo "mount -o bind /dev/pts dev/pts" >> shr-chroot.sh ; \
	  echo "mount -o bind /sys/ sys" >> shr-chroot.sh ; \
	  echo "mount -o bind /proc/ proc" >> shr-chroot.sh ; \
	  echo "#mount -o bind /proc/bus/usb proc/bus/usb" >> shr-chroot.sh ; \
	  echo "mount -o bind /tmp/ tmp" >> shr-chroot.sh ; \
	  echo "#mount -o bind /usr/src usr/src" >> shr-chroot.sh ; \
	  echo "#mount -o bind /usr/portage usr/portage" >> shr-chroot.sh ; \
	  echo "mount -o bind ../shr-unstable OE/shr-unstable" >> shr-chroot.sh ; \
	  echo "mount -o bind ../shr-testing OE/shr-testing" >> shr-chroot.sh ; \
	  echo "#mount -o bind ../shr-stable OE/shr-stable" >> shr-chroot.sh ; \
	  echo "cp -pf /etc/resolv.conf etc >/dev/null &" >> shr-chroot.sh ; \
	  echo "cp -pf /etc/hosts etc > /dev/null &" >> shr-chroot.sh ; \
	  echo "cp -pf /etc/mtab etc > /dev/null &" >> shr-chroot.sh ; \
	  echo "cp -Ppf /etc/localtime etc >/dev/null &" >> shr-chroot.sh ; \
	  echo "" >> shr-chroot.sh ; \
	  echo "chroot . /bin/bash" >> shr-chroot.sh ; \
	  echo "umount dev/pts" >> shr-chroot.sh ; \
	  echo "umount dev" >> shr-chroot.sh ; \
	  echo "umount sys" >> shr-chroot.sh ; \
	  echo "#umount usr/src" >> shr-chroot.sh ; \
	  echo "#umount usr/portage" >> shr-chroot.sh ; \
	  echo "umount tmp" >> shr-chroot.sh ; \
	  echo "umount OE/shr-unstable" >> shr-chroot.sh ; \
	  echo "umount OE/shr-testing" >> shr-chroot.sh ; \
	  echo "#umount OE/shr-stable" >> shr-chroot.sh ; \
	  echo "#umount proc/bus/usb" >> shr-chroot.sh ; \
	  echo "umount proc" >> shr-chroot.sh ; \
	)
	touch shr-chroot.sh/.git/config

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config:
	[ -e openembedded/.git/config ] || \
	( echo "setting up openembedded"; \
	  git clone git://git.openembedded.net/openembedded openembedded )
	( cd openembedded && \
	  ( git branch | egrep -e ' org.openembedded.dev$$' > /dev/null || \
	    git checkout -b org.openembedded.dev --track origin/org.openembedded.dev ))
	( cd openembedded && git checkout org.openembedded.dev )
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
	[ -e shr-stable/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-stable/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-stable/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-stable/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-stable/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-stable/ipk/\"" >> shr-stable/conf/auto.conf ; \
	)
	[ -e shr-stable/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-stable/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-stable/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-stable/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-stable/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-stable/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-stable/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-stable/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-stable/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-stable/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-stable/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-stable/conf/local.conf ; \
	)
	[ -e shr-stable/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-stable/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${GITSHA}" >> shr-stable/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-stable/conf/local-builds.inc ; \
	)
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
	[ -e shr-testing/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-testing/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-testing/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-testing/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-testing/ipk/\"" >> shr-testing/conf/auto.conf ; \
	)
	[ -e shr-testing/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-testing/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-testing/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-testing/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-testing/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-testing/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-testing/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-testing/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-testing/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-testing/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-testing/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-testing/conf/local.conf ; \
	)
	[ -e shr-testing/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-testing/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${GITSHA}" >> shr-testing/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-testing/conf/local-builds.inc ; \
	)
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
	[ -e shr-unstable/conf/site.conf ] || ( cd shr-unstable/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-unstable/conf/auto.conf ] || ( \
		echo "DISTRO = \"shr\"" > shr-unstable/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-unstable/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-unstable/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-unstable/ipk/\"" >> shr-unstable/conf/auto.conf ; \
	)
	[ -e shr-unstable/conf/local.conf ] || ( \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-unstable/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-unstable/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-unstable/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-unstable/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-unstable/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-unstable/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-unstable/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-unstable/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-unstable/conf/local.conf ; \
		echo "# enable local builds for SHR apps" >> shr-unstable/conf/local.conf ; \
		echo "#require local-builds.inc" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
	)
	[ -e shr-unstable/conf/local-builds.inc ] || ( \
			echo "INHERIT_append_pn-libphone-ui-shr = \"srctree gitpkgv\"" > shr-unstable/conf/local-builds.inc ; \
			echo "SRCREV_pn-libphone-ui-shr = \$${GITSHA}" >> shr-unstable/conf/local-builds.inc ; \
			echo "S_pn-libphone-ui-shr = \"/path/to/source//\$${PN}\"" >> shr-unstable/conf/local-builds.inc ; \
	)
	[ -e shr-unstable/conf/topdir.conf ] || echo "TOPDIR='`pwd`/shr-unstable'" > shr-unstable/conf/topdir.conf
	touch shr-unstable/.configured


.PHONY: update-common
update-common: common/.git/config
	@echo "updating common (Makefile)"
	( cd common ; git pull )

.PHONY: update-shr-chroot
update-shr-chroot: shr-chroot/.git/config
	@echo "updating shr-chroot"
	( cd shr-chroot ; \
	  git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${CHROOT_BRANCH} 2>/dev/null || \
	  git checkout --no-track -b ${CHROOT_BRANCH} origin/${CHROOT_BRANCH} ; \
	  git reset --hard origin/${CHROOT_BRANCH}; \
	  sed -i "s#bitbake:x:1026:1026::/OE:/bin/bash/#bitbake:x:`id -u`:`id -g`::/OE:/bin/bash/#g" etc/passwd; \
	  sed -i "s#bitbake:x:1026:bitbake#bitbake:x:`id -g`:bitbake#g" etc/group; \
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

.PHONY: status-shr-chroot
status-openembedded: openembedded/.git/config
	( cd shr-chroot ; git diff --stat )

# End of Makefile
