DEBIAN_VERSION=8.3.0
ARCH=i386

INSTALLERBASEIMAGE=debian-$(DEBIAN_VERSION)-$(ARCH)-netinst.iso
URL=http://cdimage.debian.org/debian-cd/$(DEBIAN_VERSION)/$(ARCH)/iso-cd

CURL=curl
CURLFLAGS=--location --progress-bar
GENISOIMAGEFLAGS=-r -J -no-emul-boot -boot-load-size 4 -boot-info-table -b isolinux/isolinux.bin -c isolinux/boot.cat ./.autoinstall
RSYNC=rsync
RSYNCFLAGS=-a -H --exclude=TRANS.TBL

UNAME=$(shell uname)

ifeq ($(UNAME),Linux)
GENISOIMAGE=genisoimage
MOUNT=fuseiso $< .mnt
UNMOUNT=fusermount -u .mnt
endif
ifeq ($(UNAME),SunOS)
GENISOIMAGE=mkisofs
MOUNT=mount -o ro -F hsfs $$(lofiadm -a ./$<) .mnt
UNMOUNT=umount .mnt ; lofiadm -d ./$<
endif

lgnas-n4b2.iso: .autoinstall/preseed.txt .autoinstall/isolinux/isolinux.cfg
	$(GENISOIMAGE) -o $@ $(GENISOIMAGEFLAGS)
	echo "LGSTORAGE" | dd of=$@ bs=1 seek=30720 count=9 conv=notrunc

.autoinstall/preseed.txt: preseed.txt .autoinstall/md5sum.txt
	cp $< $@
	sed -i "s@{{hostname}}@$(HOSTNAME)@g" $@
	sed -i "s@{{domain}}@$(DOMAIN)@g" $@
	sed -i "s@{{fullname}}@$(FULLNAME)@g" $@
	sed -i "s@{{username}}@$(USERNAME)@g" $@
	sed -i "s@{{pwhash}}@$(PASSWORD)@g" $@


PASSWORD ?= $(shell bash -c 'read -sp " please enter your preferred password  : " pwd; echo $$pwd | mkpasswd -s -m sha-512 ')
HOSTNAME ?= $(shell bash -c 'read -ep " please enter your preferred hostname  : " -i "lg-nas" hostname; echo $$hostname ')
FULLNAME ?= $(shell bash -c 'read -ep " please enter your preferred fullname  : " fullname; echo $$fullname ')
USERNAME ?= $(shell bash -c 'read -ep " please enter your preferred username  : " -i "dalai" username; echo $$username ')
DOMAIN   ?= $(shell bash -c 'read -ep " please enter your preferred domain    : " -i "local" domain  ; echo $$domain   ')

ifeq ($(ARCH),i386)
.autoinstall/isolinux/isolinux.cfg: isolinux.cfg.386 .autoinstall/md5sum.txt
	cp $< $@
endif
ifeq ($(ARCH),AMD64)
.autoinstall/isolinux/isolinux.cfg: isolinux.cfg.amd .autoinstall/md5sum.txt
	cp $< $@
endif

.autoinstall/md5sum.txt: $(INSTALLERBASEIMAGE)
	mkdir .mnt
	$(MOUNT)
	$(RSYNC) $(RSYNCFLAGS) .mnt/ .autoinstall/
	chmod -R +w .autoinstall
	$(UNMOUNT)
	rmdir .mnt
	touch $@

$(INSTALLERBASEIMAGE):
	$(CURL) $(CURLFLAGS) --output $@ $(URL)/$@

clean:
	$(RM) -r .autoinstall lgnas-n4b2.iso $(INSTALLERBASEIMAGE)
