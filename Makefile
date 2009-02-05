# Makefile for the OpenMoko SHR development system
# Licensed under the GPL v2 or later

BITBAKE_VERSION = branches/bitbake-1.8

OE_SRCREV = $(shell if [ -e shr/oe-revision ] ; then cat shr/oe-revision ; else echo org.openembedded.dev ; fi)

SHR_STABLE_MILESTONE = milestone1
SHR_STABLE_VERSION = HEAD 

SHR_MAKEFILE_URL = "http://shr.bearstech.com/repo/shr-makefile.git"
SHR_OVERLAY_URL = "http://shr.bearstech.com/repo/shr-overlay.git"

.PHONY: all
all: update build

.PHONY: prefetch
prefetch: prefetch-shr-unstable prefetch-shr-testing prefetch-shr-${SHR_STABLE_MILESTONE}

.PHONY: build
build:
	[ ! -e shr-unstable ]                 || ${MAKE} shr-unstable-image
#	[ ! -e shr-testing ]                  || ${MAKE} shr-testing-image
#	[ ! -e shr-${SHR_STABLE_MILESTONE} ]  || ${MAKE} shr-${SHR_STABLE_MILESTONE}-image

.PHONY: setup
setup:  setup-common setup-bitbake setup-openembedded \
	setup-shr-unstable setup-shr-testing setup-shr-${SHR_STABLE_MILESTONE}

.PHONY: update
update: update-common update-bitbake update-shr update-openembedded

.PHONY: status
status: status-common status-bitbake status-shr status-openembedded

.PHONY: clobber
clobber: clobber-shr-unstable clobber-shr-testing clobber-shr-${SHR_STABLE_MILESTONE}

.PHONY: distclean
distclean: distclean-bitbake distclean-openembedded \
	 distclean-shr-unstable distclean-shr-testing distclean-shr-${SHR_STABLE_MILESTONE}

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
	git clone git://git.openembedded.net/openembedded openembedded
	( cd openembedded && \
	  ( git branch | egrep -e ' org.openembedded.dev$$' > /dev/null || \
	    git checkout -b org.openembedded.dev --track origin/org.openembedded.dev ))
	( cd openembedded && git checkout `git rev-parse ${OE_SRCREV}` )
	touch openembedded/.git/config

.PHONY: patch-openembedded
.PRECIOUS: openembedded/.patched
patch-openembedded openembedded/.patched:
	[ -e openembedded/.patched ] || \
	( cd openembedded ; \
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


.PRECIOUS: shr-%/.configured
shr-%/.configured: common/.git/config bitbake/.svn/entries shr/.git/config openembedded/.git/config openembedded/.patched
	[ -d shr-$* ] || ( mkdir -p shr-$* )
	[ -e downloads ] || ( mkdir -p downloads )
	[ -e shr-$*/Makefile ] || ( cd shr-$* ; ln -sf ../common/openembedded.mk Makefile )
	[ -e shr-$*/setup-env ] || ( cd shr-$* ; ln -sf ../common/setup-env . )
	[ -e shr-$*/downloads ] || ( cd shr-$* ; ln -sf ../downloads . )
	[ -e shr-$*/bitbake ] || ( cd shr-$* ; ln -sf ../bitbake . )
	[ -e shr-$*/openembedded ] || ( cd shr-$* ; ln -sf ../openembedded . )
	[ -e shr-$*/shr ] || ( cd shr-$* ; ln -sf ../shr . )
	[ -d shr-$*/conf ] || ( mkdir -p shr-$*/conf )
	[ -e shr-$*/conf/site.conf ] || ( cd shr-$*/conf ; ln -sf ../../common/conf/site.conf . )
	[ -e shr-$*/conf/auto.conf ] || ( \
		echo "DISTRO = \"openmoko\"" > shr-$*/conf/auto.conf ; \
		echo "DISTRO_TYPE = \"$*\"" >> shr-$*/conf/auto.conf ; \
		echo "MACHINE = \"om-gta02\"" >> shr-$*/conf/auto.conf ; \
		echo "IMAGE_TARGET = \"shr-image\"" >> shr-$*/conf/auto.conf ; \
		echo "DISTRO_TARGET = \"task-shr-feed\"" >> shr-$*/conf/auto.conf ; \
		echo "INHERIT += \"rm_work\"" >> shr-$*/conf/auto.conf ; \
		echo "DISTRO_FEED_PREFIX = \"shr\"" >> shr-$*/conf/auto.conf ; \
		echo "DISTRO_FEED_URI = \"http://shr.bearstech.com/shr-$*/ipk/\"" >> shr-$*/conf/auto.conf ; \
	)
	[ -e shr-$*/conf/local.conf ] || ( \
		echo "# require conf/distro/include/moko-autorev.inc" > shr-$*/conf/local.conf ; \
		echo "# require conf/distro/include/fso-autorev.inc" >> shr-$*/conf/local.conf ; \
		echo "BBFILES += \"\$${TOPDIR}/shr/openembedded/packages/*/*.bb\"" >> shr-$*/conf/local.conf ; \
		echo "BB_GIT_CLONE_FOR_SRCREV = \"1\"" >> shr-$*/conf/local.conf ; \
		echo "OE_ALLOW_INSECURE_DOWNLOADS=1" >> shr-$*/conf/local.conf ; \
		echo "# additionally build a tar.gz image file (as needed for installing on SD)" >> shr-$*/conf/local.conf ; \
		echo "#IMAGE_FSTYPES = "jffs2 tar.gz" >> shr-$*/conf/local.conf ; \
		echo "# speed up build by parallel building - usefull for multicore cpus" >> shr-$*/conf/local.conf ; \
		echo "#PARALLEL_MAKE = \"-j 4\"" >> shr-$*/conf/local.conf ; \
		echo "#BB_NUMBER_THREADS = \"4\"" >> shr-$*/conf/local.conf ; \
		echo "# avoid multiple locales generation to speedup the build and save space" >> shr-$*/conf/local.conf ; \
		echo "#GLIBC_GENERATE_LOCALES = \"en_US.UTF-8\"" >> shr-$*/conf/local.conf ; \
		echo "# completely disable generation of locales. If building qemu fails this might help" >> shr-$*/conf/local.conf ; \
		echo "#ENABLE_BINARY_LOCALE_GENERATION = \"0\"" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcrevs.inc" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/sane-srcdates.inc" >> shr-$*/conf/local.conf ; \
		echo "require conf/distro/include/shr-autorev.inc" >> shr-$*/conf/local.conf ; \
		case "shr-$*" in shr-unstable) echo "require conf/distro/include/shr-autorev-unstable.inc" >> shr-$*/conf/local.conf ;; esac ; \
	)
	rm -rf shr-$*/tmp/cache
	touch shr-$*/.configured

.PHONY: update-common
update-common: common/.git/config
	( cd common ; git pull )

.PHONY: update-bitbake
update-bitbake: bitbake/.svn/entries
	( cd bitbake ; svn up )

.PHONY: update-openembedded
update-openembedded: openembedded/.git/config
	( cd openembedded ; \
	  rm -f .patched ; git clean -d -f ; git reset --hard ; git fetch ; \
	  git checkout `git rev-parse ${OE_SRCREV}` ; \
	  ../shr/patches/do-patch )

.PHONY: update-shr
update-shr: shr/.git/config
	( cd shr ; git pull )

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
