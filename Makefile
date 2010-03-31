#
# Makefile for sos system support tools
#

NAME	= sos
VERSION = $(shell echo `awk '/^Version:/ {print $$2}' sos.spec`)
RELEASE = $(shell echo `awk '/^Release:/ {gsub(/\%.*/,""); print $2}' sos.spec`)
REPO = http://svn.fedorahosted.org/svn/sos
TMPDIR = /tmp/$(NAME)-$(VERSION)

SUBDIRS = po sos sos/plugins testsuite
PYFILES = $(wildcard *.py)

RPM_BUILD_DIR = rpm-build
RPM_DEFINES = --define "_topdir %(pwd)/$(RPM_BUILD_DIR)" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir %{_topdir}"
RPM = rpmbuild
RPM_WITH_DIRS = $(RPM) $(RPM_DEFINES)

build:
	for d in $(SUBDIRS); do make -C $$d; [ $$? = 0 ] || exit 1 ; done

install:
	mkdir -p $(DESTDIR)/usr/sbin
	mkdir -p $(DESTDIR)/usr/share/man/man1
	mkdir -p $(DESTDIR)/usr/share/$(NAME)/extras
	@gzip -c man/en/sosreport.1 > sosreport.1.gz
	mkdir -p $(DESTDIR)/etc
	install -m755 sosreport $(DESTDIR)/usr/sbin/sosreport
	install -m644 sosreport.1.gz $(DESTDIR)/usr/share/man/man1/.
	install -m644 LICENSE README TODO $(DESTDIR)/usr/share/$(NAME)/.
	install -m644 $(NAME).conf $(DESTDIR)/etc/$(NAME).conf
	install -m644 gpgkeys/rhsupport.pub $(DESTDIR)/usr/share/$(NAME)/.
	for d in $(SUBDIRS); do make DESTDIR=`cd $(DESTDIR); pwd` -C $$d install; [ $$? = 0 ] || exit 1; done

$(NAME)-$(VERSION).tar.gz: gpgkey
	@rm -rf $(NAME)-$(VERSION).tar.gz
	@rm -rf $(TMPDIR)
	@svn export --force $(PWD) $(TMPDIR)
	@mkdir -p $(TMPDIR)/gpgkeys
	@cp gpgkeys/rhsupport.pub $(TMPDIR)/gpgkeys/.
	@tar Ccvzf /tmp $(NAME)-$(VERSION).tar.gz $(NAME)-$(VERSION)
	@mkdir $(RPM_BUILD_DIR)
	@cp $(NAME)-$(VERSION).tar.gz $(RPM_BUILD_DIR)/.
	@rm -rf $(NAME)-$(VERSION).tar.gz
	@echo "Archive is $(NAME)-$(VERSION).tar.gz"

clean:
	@rm -fv *~ .*~ changenew ChangeLog.old $(NAME)-$(VERSION).tar.gz sosreport.1.gz
	@rm -rf rpm-build
	@rm -rfv $(TMPDIR)
	@for i in `find . -iname *.pyc`; do \
		rm $$i; \
	done; \
	for d in $(SUBDIRS); do make -C $$d clean ; done

srpm: clean $(NAME)-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) -ts $(RPM_BUILD_DIR)/$(NAME)-$(VERSION).tar.gz

rpm: clean $(NAME)-$(VERSION).tar.gz
	$(RPM_WITH_DIRS) -tb $(RPM_BUILD_DIR)/$(NAME)-$(VERSION).tar.gz

gpgkey:
	@echo "Building gpg key"
	@test -f gpgkeys/rhsupport.pub && echo "GPG key already exists." || \
	gpg --batch --gen-key gpgkeys/gpg.template
