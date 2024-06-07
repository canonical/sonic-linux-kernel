.ONESHELL:
SHELL = /bin/bash
.SHELLFLAGS += -e

ifeq ($(BLDENV),jammy) 
# jammy kernel build section ########
KERNEL_ABI_MINOR_VERSION = 39
KVERSION_SHORT ?= 6.2.0-$(KERNEL_ABI_MINOR_VERSION)
KVERSION ?= $(KVERSION_SHORT)-amd64
KERNEL_VERSION ?= 6.2.0
KERNEL_SUBVERSION ?= 39
kernel_procure_method ?= build
CONFIGURED_ARCH ?= amd64
CONFIGURED_PLATFORM ?= vs
SECURE_UPGRADE_MODE ?=
SECURE_UPGRADE_SIGNING_CERT ?=

LINUX_HEADER_COMMON = linux-headers-$(KVERSION_SHORT)-common_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_all.deb
LINUX_HEADER_AMD64 = linux-headers-$(KVERSION)_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
ifeq ($(CONFIGURED_ARCH), armhf)
	LINUX_IMAGE = linux-image-$(KVERSION)_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
else
	LINUX_IMAGE = linux-image-$(KVERSION)-unsigned_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
endif
MAIN_TARGET = $(LINUX_HEADER_COMMON)

LINUX_MODULES = linux-modules-$(KVERSION_SHORT)-common_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
DERIVED_TARGETS = $(LINUX_MODULES) $(LINUX_IMAGE)

ifneq ($(kernel_procure_method), build)
# Downloading kernel

LINUX_HEADER_COMMON_URL = "http://security.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.5/linux-headers-6.5.0-15-generic_6.5.0-15.15~22.04.1_amd64.deb"
LINUX_MODULES_URL = "http://security.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.5/linux-modules-6.5.0-15-generic_6.5.0-15.15~22.04.1_amd64.deb"
LINUX_IMAGE_URL = "http://security.ubuntu.com/ubuntu/pool/main/l/linux-hwe-6.5/linux-image-unsigned-6.5.0-15-generic_6.5.0-15.15~22.04.1_amd64.deb"

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	# Obtaining the Debian kernel packages
	####rm -rf $(BUILD_DIR)
	####wget --no-use-server-timestamps -O $(LINUX_HEADER_COMMON) $(LINUX_HEADER_COMMON_URL)
	####wget --no-use-server-timestamps -O $(LINUX_MODULES) $(LINUX_MODULES_URL)
	####wget --no-use-server-timestamps -O $(LINUX_IMAGE) $(LINUX_IMAGE_URL)
	cp ubuntu-linux-$(KERNEL_VERSION)/* ./ 

ifneq ($(DEST),)
	mv $(DERIVED_TARGETS) $* $(DEST)/
endif

$(addprefix $(DEST)/, $(DERIVED_TARGETS)): $(DEST)/% : $(DEST)/$(MAIN_TARGET)

else
# Jammy Building kernel

BUILD_DIR=linux-$(KERNEL_VERSION)
SOURCE_FILE_BASE_URL="https://git.launchpad.net/~ubuntu-kernel/ubuntu/+source/linux/+git/jammy"
SOURCE_FILE_BRANCH = "hwe-6.2-prep"

NON_UP_DIR = /tmp/non_upstream_patches

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	# Obtaining the Debian kernel source
	rm -rf $(BUILD_DIR)
	git clone -b $(SOURCE_FILE_BRANCH) $(SOURCE_FILE_BASE_URL) $(BUILD_DIR)

	pushd $(BUILD_DIR)

	# patching anything that could affect following configuration generation.
	stg init
	stg import -s ../patch/series.ubuntu

	# Optionally add/remove kernel options
	#if [ -f ../manage-config ]; then
	#	../manage-config $(CONFIGURED_ARCH) $(CONFIGURED_PLATFORM) $(SECURE_UPGRADE_MODE) $(SECURE_UPGRADE_SIGNING_CERT)
	#fi

	# Building a custom kernel from ubuntu kernel source
	fakeroot make -f debian/rules clean
	chmod a+x debian/scripts/*
	chmod a+x debian/scripts/misc/*
	fakeroot debian/rules binary-headers binary-generic
	popd

ifneq ($(DEST),)
	mv $(DERIVED_TARGETS) $* $(DEST)/
endif

$(addprefix $(DEST)/, $(DERIVED_TARGETS)): $(DEST)/% : $(DEST)/$(MAIN_TARGET)

endif # building kernel
#end of jammy kernel build section ####

else # none-jammy build 

KERNEL_ABI_MINOR_VERSION = 2
KVERSION_SHORT ?= 6.1.0-11-$(KERNEL_ABI_MINOR_VERSION)
KVERSION ?= $(KVERSION_SHORT)-amd64
KERNEL_VERSION ?= 6.1.38
KERNEL_SUBVERSION ?= 4
kernel_procure_method ?= build
CONFIGURED_ARCH ?= amd64
CONFIGURED_PLATFORM ?= vs
SECURE_UPGRADE_MODE ?=
SECURE_UPGRADE_SIGNING_CERT ?=

LINUX_HEADER_COMMON = linux-headers-$(KVERSION_SHORT)-common_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_all.deb
LINUX_HEADER_AMD64 = linux-headers-$(KVERSION)_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
ifeq ($(CONFIGURED_ARCH), armhf)
	LINUX_IMAGE = linux-image-$(KVERSION)_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
else
	LINUX_IMAGE = linux-image-$(KVERSION)-unsigned_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_$(CONFIGURED_ARCH).deb
endif

MAIN_TARGET = $(LINUX_HEADER_COMMON)
DERIVED_TARGETS = $(LINUX_HEADER_AMD64) $(LINUX_IMAGE)

ifneq ($(kernel_procure_method), build)
# Downloading kernel

# TBD, need upload the new kernel packages
LINUX_HEADER_COMMON_URL = "https://sonicstorage.blob.core.windows.net/packages/kernel-public/linux-headers-$(KVERSION_SHORT)-common_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_all.deb?sv=2015-04-05&sr=b&sig=JmF0asLzRh6btfK4xxfVqX%2F5ylqaY4wLkMb5JwBJOb8%3D&se=2128-12-23T19%3A05%3A28Z&sp=r"

LINUX_HEADER_AMD64_URL = "https://sonicstorage.blob.core.windows.net/packages/kernel-public/linux-headers-$(KVERSION_SHORT)-amd64_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_amd64.deb?sv=2015-04-05&sr=b&sig=%2FD9a178J4L%2FN3Fi2uX%2FWJaddpYOZqGmQL4WAC7A7rbA%3D&se=2128-12-23T19%3A06%3A13Z&sp=r"

LINUX_IMAGE_URL = "https://sonicstorage.blob.core.windows.net/packages/kernel-public/linux-image-$(KVERSION_SHORT)-amd64_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION)_amd64.deb?sv=2015-04-05&sr=b&sig=oRGGO9xJ6jmF31KGy%2BwoqEYMuTfCDcfILKIJbbaRFkU%3D&se=2128-12-23T19%3A06%3A47Z&sp=r"

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	# Obtaining the Debian kernel packages
	rm -rf $(BUILD_DIR)
	wget --no-use-server-timestamps -O $(LINUX_HEADER_COMMON) $(LINUX_HEADER_COMMON_URL)
	wget --no-use-server-timestamps -O $(LINUX_HEADER_AMD64) $(LINUX_HEADER_AMD64_URL)
	wget --no-use-server-timestamps -O $(LINUX_IMAGE) $(LINUX_IMAGE_URL)

ifneq ($(DEST),)
	mv $(DERIVED_TARGETS) $* $(DEST)/
endif

$(addprefix $(DEST)/, $(DERIVED_TARGETS)): $(DEST)/% : $(DEST)/$(MAIN_TARGET)

else
# Building kernel

DSC_FILE = linux_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION).dsc
DEBIAN_FILE = linux_$(KERNEL_VERSION)-$(KERNEL_SUBVERSION).debian.tar.xz
ORIG_FILE = linux_$(KERNEL_VERSION).orig.tar.xz
BUILD_DIR=linux-$(KERNEL_VERSION)
SOURCE_FILE_BASE_URL="https://sonicstorage.blob.core.windows.net/debian-security/pool/updates/main/l/linux"

DSC_FILE_URL = "$(SOURCE_FILE_BASE_URL)/$(DSC_FILE)"
DEBIAN_FILE_URL = "$(SOURCE_FILE_BASE_URL)/$(DEBIAN_FILE)"
ORIG_FILE_URL = "$(SOURCE_FILE_BASE_URL)/$(ORIG_FILE)"
NON_UP_DIR = /tmp/non_upstream_patches

$(addprefix $(DEST)/, $(MAIN_TARGET)): $(DEST)/% :
	# Include any non upstream patches
	rm -rf $(NON_UP_DIR)
	mkdir -p $(NON_UP_DIR)

	if [ x${INCLUDE_EXTERNAL_PATCHES} == xy ]; then
		if [ ! -z ${EXTERNAL_KERNEL_PATCH_URL} ]; then
			wget $(EXTERNAL_KERNEL_PATCH_URL) -O patches.tar
			tar -xf patches.tar -C $(NON_UP_DIR)
		else
			if [ -d "$(EXTERNAL_KERNEL_PATCH_LOC)" ]; then
				cp -r $(EXTERNAL_KERNEL_PATCH_LOC)/* $(NON_UP_DIR)/
			fi
		fi
	fi

	if [ -f "$(NON_UP_DIR)/external-changes.patch" ]; then
		cat $(NON_UP_DIR)/external-changes.patch
		git stash -- patch/
		git apply $(NON_UP_DIR)/external-changes.patch
	fi

	if [ -d "$(NON_UP_DIR)/patches" ]; then
		echo "Copy the non upstream patches"
		cp $(NON_UP_DIR)/patches/*.patch patch/
	fi

	# Obtaining the Debian kernel source
	rm -rf $(BUILD_DIR)
	wget -O $(DSC_FILE) $(DSC_FILE_URL)
	wget -O $(ORIG_FILE) $(ORIG_FILE_URL)
	wget -O $(DEBIAN_FILE) $(DEBIAN_FILE_URL)

	dpkg-source -x $(DSC_FILE)

	pushd $(BUILD_DIR)
	git init
	git add -f *
	git commit -qm "check in all loose files and diffs"

	# patching anything that could affect following configuration generation.
	stg init
	stg import -s ../patch/preconfig/series

	# re-generate debian/rules.gen, requires kernel-wedge
	debian/bin/gencontrol.py

	# generate linux build file for amd64_none_amd64
	DEB_HOST_ARCH=armhf fakeroot make -f debian/rules.gen setup_armhf_none_armmp
	DEB_HOST_ARCH=arm64 fakeroot make -f debian/rules.gen setup_arm64_none_arm64
	DEB_HOST_ARCH=amd64 fakeroot make -f debian/rules.gen setup_amd64_none_amd64

	# Applying patches and configuration changes
	git add debian/build/build_armhf_none_armmp/.config -f
	git add debian/build/build_arm64_none_arm64/.config -f
	git add debian/build/build_amd64_none_amd64/.config -f
	git add debian/config.defines.dump -f
	git add debian/control -f
	git add debian/rules.gen -f
	git add debian/tests/control -f
	git add debian/*.maintscript -f
	git add debian/*.bug-presubj -f
	git commit -m "unmodified debian source"

	# Learning new git repo head (above commit) by calling stg repair.
	stg repair
	stg import -s ../patch/series

	# Optionally add/remove kernel options
	if [ -f ../manage-config ]; then
		../manage-config $(CONFIGURED_ARCH) $(CONFIGURED_PLATFORM) $(SECURE_UPGRADE_MODE) $(SECURE_UPGRADE_SIGNING_CERT)
	fi

	# Building a custom kernel from Debian kernel source
	ARCH=$(CONFIGURED_ARCH) DEB_HOST_ARCH=$(CONFIGURED_ARCH) DEB_BUILD_PROFILES=nodoc fakeroot make -f debian/rules -j $(shell nproc) binary-indep
ifeq ($(CONFIGURED_ARCH), armhf)
	ARCH=$(CONFIGURED_ARCH) DEB_HOST_ARCH=$(CONFIGURED_ARCH) fakeroot make -f debian/rules.gen -j $(shell nproc) binary-arch_$(CONFIGURED_ARCH)_none_armmp
else
	ARCH=$(CONFIGURED_ARCH) DEB_HOST_ARCH=$(CONFIGURED_ARCH) fakeroot make -f debian/rules.gen -j $(shell nproc) binary-arch_$(CONFIGURED_ARCH)_none_$(CONFIGURED_ARCH)
endif
	popd

ifneq ($(DEST),)
	mv $(DERIVED_TARGETS) $* $(DEST)/
endif

$(addprefix $(DEST)/, $(DERIVED_TARGETS)): $(DEST)/% : $(DEST)/$(MAIN_TARGET)

endif # building kernel

endif # none-jammy build
