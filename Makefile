#!/usr/bin/make -f

MAKEFLAGS = rR

SHELL := /bin/sh
LANG = C
LC_ALL = $(LANG)

export SHELL LANG LC_ALL

THIS_MAKEFILE = $(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
PREFIX = $(shell cd -- $(dir $(THIS_MAKEFILE)) && pwd -P)

LIBDIR = $(PREFIX)/lib
PYLIBDIR = $(LIBDIR)/python
UIDIR = $(PREFIX)/ui
MEDIADIR = $(PREFIX)/media
BINDIR = $(PREFIX)/bin

UIXMLS = $(wildcard $(UIDIR)/*.ui)
UIFILES = $(notdir $(UIXMLS))
UINAMES = $(basename $(UIFILES))
UILIBNAMES = $(UINAMES:=_ui)
UILIBFILES = $(foreach UILIBNAME,$(UILIBNAMES),$(PYLIBDIR)/$(UILIBNAME).py)
UIPYCFILES = $(UILIBFILES:.py=.pyc)
UIPYOFILES = $(UILIBFILES:.py=.pyo)
UIBYTECODE = $(UIPYCFILES) $(UIPYOFILES)

RCDIRS = $(MEDIADIR)
RCNAMES = $(notdir $(RCDIRS))
RCFILES = $(RCDIRS:=.qrc)
RCLIBNAMES = $(RCNAMES:=_rc)
RCLIBFILES = $(foreach RCLIBNAME,$(RCLIBNAMES),$(PYLIBDIR)/$(RCLIBNAME).py)
RCPYCFILES = $(RCLIBFILES:.py=.pyc)
RCPYOFILES = $(RCLIBFILES:.py=.pyo)
RCBYTECODE = $(RCPYCFILES) $(RCPYOFILES)

BYTECODE = $(UIBYTECODE) $(RCBYTECODE)
PYLIBS = $(UILIBFILES) $(RCLIBFILES)
JUNK = $(BYTECODE) $(PYLIBS) $(RCFILES)

QTV = 5
PYUIC = pyuic$(QTV)
PYRCC = pyrcc$(QTV)
PYTHON = python
MKQRC = $(BINDIR)/mkqrc

PYUICFALGS =
PYRCCFLAGS =
MKQRCFLAGS = -p / -e UTF-8

$(PYLIBDIR)/%_rc.py: $(PREFIX)/%.qrc | $(PYLIBDIR)
	$(PYRCC) $(PYRCCFLAGS) $(OUT) $@ $^

$(PREFIX)/%.qrc: $(PREFIX)/%
	$(PYTHON) $(MKQRC) $(MKQRCFLAGS) $^ $@

ECHO = echo
MKDIR = mkdir -p
RMDIR = rmdir
RM = rm -f
CP = cp -an
MV = mv -n

OUT = -o

.DEFAULT_GOAL := all

all: build

build build-all: ui

ui: rc $(UIBYTECODE)

$(PYLIBDIR)/%_ui.py: $(UIDIR)/%.ui | $(PYLIBDIR)
	$(PYUIC) $(PYUICFLAGS) $(OUT) $@ $^

%.pyc: %.py
	$(MAKE) opt LIB=$< OPT=

%.pyo: %.py
	$(MAKE) opt LIB=$< OPT=-OO

opt: FORCE
	PYTHONPATH=$(dir $(LIB)) $(PYTHON) $(OPT) -c 'import $(notdir $(basename $(LIB)))'

rc: $(RCBYTECODE)

$(PYLIBDIR)/%_rc.py: $(PREFIX)/%.qrc | $(PYLIBDIR)
	$(PYRCC) $(PYRCCFLAGS) $(OUT) $@ $^

$(PREFIX)/%.qrc: $(PREFIX)/%
	$(PYTHON) $(MKQRC) $(MKQRCFLAGS) $^ $@

test check: build FORCE

run: build FORCE

install: test FORCE

clean: FORCE
	-$(RM) $(JUNK)

dist-clean distclean: clean FORCE

dist: dist-clean FORCE

FORCE: ;

.PHONY: all build build-all ui rc opt test check run \
	install clean dist-clean distclean dist FORCE

.PRECIOUS: $(UILIBFILES) $(RCLIBFILES) $(UIBYTECODE)

.SUFFIXES: ;

.DEFAULT: ;

$(LIBDIR) $(UIDIR) $(BINDIR) $(MEDIADIR): | $(PREFIX)

$(PYLIBDIR): | $(LIBDIR)

$(PREFIX) $(LIBDIR) $(UIDIR) $(BINDIR) $(MEDIADIR) $(PYLIBDIR):
	$(MKDIR) $@

$(THIS_MAKEFILE): ;

%: ;

