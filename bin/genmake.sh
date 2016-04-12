#!/bin/sh -

set -euf

PATH=/usr/bin:/bin
LANG=C
LC_ALL=C

export PATH LANG LC_ALL

make="$(which make)"
test -x "$make" || exit

eol="$(printf "\n.")"; eol="${eol%.}"

printf "#!%s -f\n\n" "$make"

( /usr/bin/env -i "$make" -p -rR -f /dev/null 2>/dev/null || true ) |
grep -E -v -e "(^(\$|[#<?*+@%^]|(\\.(FEATURES|INCLUDE_DIRS|VARIABLES)|CURDIR|M(FLAGS|AKE(FILE(PATH|S|_LIST)|LEVEL|_(COMMAND|VERSION))?))\\s+)|:\$)" || true

printf "

LANG = C
LC_ALL = \$(LANG)

export LANG LC_ALL

THIS_MAKEFILE = \$(word \$(words \$(MAKEFILE_LIST)), \$(MAKEFILE_LIST))
PREFIX = \$(shell cd -- \$(dir \$(THIS_MAKEFILE)) && pwd -P)

ECHO = echo
MKDIR = mkdir -p
RMDIR = rmdir
RM = rm -f
CP = cp -an
MV = mv -n

OUT = -o

all: build

build build-all: ;

test check: build FORCE

run: build FORCE

install: test FORCE

clean: FORCE

dist-clean distclean: clean FORCE

dist: dist-clean FORCE

FORCE: ;

.PHONY: all build build-all test check run \\
\tinstall clean dist-clean distclean dist FORCE

.PRECIOUS: ;

.SUFFIXES: ;

.DEFAULT: ;

\$(PREFIX):
\t\$(MKDIR) \$@

\$(THIS_MAKEFILE): ;

%%: ;

"
