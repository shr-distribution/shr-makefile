# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

BITBAKE_VERSION = branches/bitbake-1.8

OE_SRCREV = $(shell if [ -e shr/oe-revision ] ; then cat shr/oe-revision ; else echo org.openembedded.dev ; fi)

SHR_TESTING_BRANCH_SHR = testing
SHR_TESTING_BRANCH_OE = fso/milestone5

SHR_UNSTABLE_BRANCH_SHR = master
SHR_UNSTABLE_BRANCH = fso/milestone5.5

SHR_MAKEFILE_URL = "http://shr.bearstech.com/repo/shr-makefile.git"
SHR_OVERLAY_URL = "http://shr.bearstech.com/repo/shr-overlay.git"

.PHONY: all
all: update build

.PHONY: setup
setup:  setup-common setup-bitbake setup-shr setup-openembedded \
	setup-shr-unstable setup-shr-testing 

.PHONY: prefetch
prefetch: prefetch-shr-unstable prefetch-shr-testing 

.PHONY: update
update: 
	[ ! -e common ] || ${MAKE} update-common 
	[ ! -e bitbake ] || ${MAKE} update-bitbake 
	[ ! -e shr ] || ${MAKE} update-shr 
	[ ! -e openembedded ] || ${MAKE} update-openembedded 
	[ ! -e shr-testing ] || ${MAKE} update-shr-testing 
	[ ! -e shr-unstable ] || ${MAKE} update-shr-unstable

.PHONY: build
build:
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-image
	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-image
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-packages
	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-packages

.PHONY: status
status: status-common status-bitbake status-shr status-openembedded

.PHONY: clobber
clobber: clobber-shr-unstable clobber-shr-testing

.PHONY: distclean
distclean: distclean-bitbake distclean-openembedded \
	 distclean-shr-unstable distclean-shr-testing

.PHONY: prefetch-%
prefetch-%: %/.configured
	( cd $* ; ${MAKE} prefetch )


.PHONY: shr-%-image
shr-%-image: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k image )
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k image )

.PHONY: shr-%-packages
shr-%-packages: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta01 ; \
	  ${MAKE} -k distro index )
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} setup-machine-om-gta02 ; \
	  ${MAKE} -k distro index )

.PHONY: shr-%-index
shr-%-index: shr-%/.configured
	( cd shr-$* ; \
	  ${MAKE} setup-image-shr-image ; \
	  ${MAKE} -k index )

.PHONY: setup-common
.PRECIOUS: common/.git/config
setup-common common/.git/config:
	[ -e common/.git/config ] || \
	( git clone ${SHR_MAKEFILE_URL} common && \
	  rm -f Makefile && \
	  ln -s common/Makefile Makefile )
	touch common/.git/config

.PHONY: setup-bitbake
.PRECIOUS: bitbake/.svn/entries
setup-bitbake bitbake/.svn/entries:
	[ -e bitbake/.svn/entries ] || \
	( svn co svn://svn.berlios.de/bitbake/${BITBAKE_VERSION} bitbake )
	touch bitbake/.svn/entries

.PHONY: setup-openembedded
.PRECIOUS: openembedded/.git/config
setup-openembedded openembedded/.git/config: shr/.git/config
	[ -e openembedded/.git/config ] || \
	( git clone git://git.openembedded.net/openembedded openembedded )
	( cd openembedded && \
	  ( git branch | egrep -e ' org.openembedded.dev$$' > /dev/null || \
	    git checkout -b org.openembedded.dev --track origin/org.openembedded.dev ))
	( cd openembedded && git checkout org.openembedded.dev )
	touch openembedded/.git/config

.PHONY: patch-openembedded
.PRECIOUS: openembedded/.patched
patch-openembedded openembedded/.patched:
	[ -e shr-testing/openembedded/.patched ] || \
	( cd shr-testing/openembedded ; \
	  ../shr/patches/do-patch )

.PHONY: setup-shr
.PRECIOUS: shr/.git/config
setup-shr shr/.git/config:
	[ -e shr/.git/config ] || \
	( git clone ${SHR_OVERLAY_URL} shr )
	touch shr/.git/config

.PHONY: setup-%
setup-%:
	${MAKE} $*/.configured


.PRECIOUS: shr-testing/.configured
shr-testing/.configured: common/.git/config bitbake/.svn/entries shr/.git/config openembedded/.git/config
	[ -d shr-testing ] || ( mkdir -p shr-testing )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-testing/Makefile ] || ( cd shr-testing ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-testing/setup-env ] || ( cd shr-testing ; ln -sf ../common/setup-env . )
	[ -e shr-testing/downloads ] || ( cd shr-testing ; ln -sf ../downloads . )
	[ -e shr-testing/bitbake ] || ( cd shr-testing ; ln -sf ../bitbake . )
	[ -e shr-testing/shr ] || ( cd shr-testing ; \
	  git clone --reference ../shr ${SHR_OVERLAY_URL} shr; \
	  cd shr ; \
	  case "${SHR_TESTING_BRANCH_SHR}" in master) : ;; *) git checkout --no-track -b ${SHR_TESTING_BRANCH_SHR} origin/${SHR_TESTING_BRANCH_SHR} ;; esac )
	[ -e shr-testing/openembedded ] || ( cd shr-testing ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout --no-track -b ${SHR_TESTING_BRANCH_OE} origin/${SHR_TESTING_BRANCH_OE}; \
	  ../shr/patches/do-patch )
	[ -d shr-testing/conf ] || ( mkdir -p shr-testing/conf )
	[ -e shr-testing/conf/site.conf ] || ( cd shr-testing/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-testing/conf/auto.conf ] || ( \
		echo "DISTRO = \"openmoko\"" > shr-testing/conf/auto.conf ; \
		echo "DISTRO_TYPE = \"testing\"" >> shr-testing/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-testing/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-testing/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-testing/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-testing/ipk/\"" >> shr-testing/conf/auto.conf ; \
	)
	[ -e shr-testing/conf/local.conf ] || ( \
		echo "# require conf/distro/include/moko-autorev.inc" > shr-testing/conf/local.conf ; \
		echo "# require conf/distro/include/fso-autorev.inc" >> shr-testing/conf/local.conf ; \
		echo "BBFILES += \"\$${TOPDIR}/shr/openembedded/packages/*/*.bb\"" >> shr-testing/conf/local.conf ; \
		echo "BB_GIT_CLONE_FOR_SRCREV = \"1\"" >> shr-testing/conf/local.conf ; \
		echo "OE_ALLOW_INSECURE_DOWNLOADS=1" >> shr-testing/conf/local.conf ; \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-testing/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-testing/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-testing/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-testing/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-testing/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-testing/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-testing/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-testing/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-testing/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcrevs.inc" >> shr-testing/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcdates.inc" >> shr-testing/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-testing/conf/local.conf ; \
	)
	rm -rf shr-testing/tmp/cache
	touch shr-testing/.configured

.PRECIOUS: shr-unstable/.configured
shr-unstable/.configured: common/.git/config bitbake/.svn/entries shr/.git/config openembedded/.git/config
	[ -d shr-unstable ] || ( mkdir -p shr-unstable )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-unstable/Makefile ] || ( cd shr-unstable ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-unstable/setup-env ] || ( cd shr-unstable ; ln -sf ../common/setup-env . )
	[ -e shr-unstable/downloads ] || ( cd shr-unstable ; ln -sf ../downloads . )
	[ -e shr-unstable/bitbake ] || ( cd shr-unstable ; ln -sf ../bitbake . )
	[ -e shr-unstable/shr ] || ( cd shr-unstable ; \
	  git clone --reference ../shr ${SHR_OVERLAY_URL} shr; \
	  cd shr ; \
	  case "${SHR_UNSTABLE_BRANCH_SHR}" in master) : ;; *) git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_SHR} origin/${SHR_UNSTABLE_BRANCH_SHR} ;; esac )
	[ -e shr-unstable/openembedded ] || ( cd shr-unstable ; \
	  git clone --reference ../openembedded git://git.openembedded.net/openembedded openembedded; \
	  cd openembedded ; \
	  git checkout --no-track -b ${SHR_UNSTABLE_BRANCH_OE} origin/${SHR_UNSTABLE_BRANCH_OE}; \
	  ../shr/patches/do-patch )
	[ -d shr-unstable/conf ] || ( mkdir -p shr-unstable/conf )
	[ -e shr-unstable/conf/site.conf ] || ( cd shr-unstable/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-unstable/conf/auto.conf ] || ( \
		echo "DISTRO = \"openmoko\"" > shr-unstable/conf/auto.conf ; \
		echo "DISTRO_TYPE = \"testing\"" >> shr-unstable/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-unstable/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-lite-image\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-unstable/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-unstable/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://build.shr-project.org/shr-unstable/ipk/\"" >> shr-unstable/conf/auto.conf ; \
	)
	[ -e shr-unstable/conf/local.conf ] || ( \
		echo "# require conf/distro/include/moko-autorev.inc" > shr-unstable/conf/local.conf ; \
		echo "# require conf/distro/include/fso-autorev.inc" >> shr-unstable/conf/local.conf ; \
		echo "BBFILES += \"\$${TOPDIR}/shr/openembedded/packages/*/*.bb\"" >> shr-unstable/conf/local.conf ; \
		echo "BB_GIT_CLONE_FOR_SRCREV = \"1\"" >> shr-unstable/conf/local.conf ; \
		echo "OE_ALLOW_INSECURE_DOWNLOADS=1" >> shr-unstable/conf/local.conf ; \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-unstable/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = \"jffs2 tar.gz\"" >> shr-unstable/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-unstable/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-unstable/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-unstable/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-unstable/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-unstable/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-unstable/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcrevs.inc" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcdates.inc" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-unstable/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev-unstable.inc" >> shr-unstable/conf/local.conf ; \
	)
	rm -rf shr-unstable/tmp/cache
	touch shr-unstable/.configured

.PHONY: update-common
update-common: common/.git/config
	( cd common ; git pull )

.PHONY: update-bitbake
update-bitbake: bitbake/.svn/entries
	( cd bitbake ; svn up )

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	( cd openembedded ; git pull )

.PHONY: update-shr
update-shr: shr/.git/config
	( cd shr ; git pull )

.PHONY: update-shr-testing
update-shr-testing: shr-testing/.configured
	( cd shr-testing/shr ; \
	  git fetch ; \
	  git checkout ${SHR_TESTING_BRANCH_SHR} ; \
	  git reset --hard origin/${SHR_TESTING_BRANCH_SHR} )
	( cd shr-testing/openembedded ; \
	  rm -f .patched ; git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_TESTING_BRANCH_OE} ; git reset --hard origin/${SHR_TESTING_BRANCH_OE} ; \
	  ../shr/patches/do-patch )

.PHONY: update-shr-unstable
update-shr-unstable: shr-unstable/.configured
	( cd shr-unstable/shr ; \
	  git fetch ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_SHR} ; \
	  git reset --hard origin/${SHR_UNSTABLE_BRANCH_SHR} )
	( cd shr-unstable/openembedded ; \
	  rm -f .patched ; git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout ${SHR_UNSTABLE_BRANCH_OE} ; git reset --hard origin/${SHR_UNSTABLE_BRANCH_OE} ; \
	  ../shr/patches/do-patch )

.PHONY: status-common
status-common: common/.git/config
	( cd common ; git diff --stat )

.PHONY: status-bitbake
status-bitbake: bitbake/.svn/entries
	( cd bitbake ; svn status )

.PHONY: status-openembedded
status-openembedded: openembedded/.git/config
	( cd openembedded ; git diff --stat )

.PHONY: status-shr
status-shr: shr/.git/config
	( cd shr ; git status )

.PHONY: clobber-%
clobber-%:
	[ ! -e $*/Makefile ] || ( cd $* ; ${MAKE} clobber )

.PHONY: distclean-bitbake
distclean-bitbake:
	rm -rf bitbake

.PHONY: distclean-openembedded
distclean-openembedded:
	rm -rf openembedded

.PHONY: distclean-shr
distclean-shr:
	rm -rf shr

.PHONY: distclean-%
distclean-%:
	rm -rf $*

#.PHONY: push
#push: push-common

#.PHONY: push-common
#push-common: update-common
#	( cd common ; git push --all ssh://git@git.freesmartphone.org/fso-makefile.git )

# End of Makefile
