#!/bin/sh -

set -euf

isabs ()
{
	case "$1" in (/*) ;; (*) false ;; esac
}

abspath ()
{
	isabs "$1" || set -- "${2:-"$(pwd)"}"/"$1"
	printf "%s\n" "$1"
}

realpath ()
(
	path="$(abspath "$1")" maxdepth=${2:-16} depth=0
	while test $depth -lt $maxdepth; do
		test -d "$path" && name="" || name="${path##*/}"
		dir="${path%/"$name"}"
		test -d "$dir" || break
		dir="$(cd "$dir" && pwd -P)"
		path="$dir${name:+/"$name"}"
		test -h "$path" || break
		path="$(abspath "$(readlink "$path")" "$dir")"
		depth=$((depth + 1))
	done
	printf "%s\n" "$path"
)

script="$(realpath "$0")"
prog="${script##*/}"
prefix="${script%/"$prog"}"

cd "$prefix"/../ || exit
test -d ui || mkdir -p ui && cd ui || exit

libdir=~/Library
prefs="$libdir"/Preferences
state="$libdir"/"Saved Application State"
app=Designer

rm -rf	~/.designer/
for name in com.qtproject com.trolltech org.python
do
	rm -rf	"$prefs"/"$name".plist \
		"$prefs"/"$name".Designer.plist \
		"$state"/"$name".Designer.savedState/
done

exec 9<>/dev/null 0<&9 1>&9 2>&9 9>&-
trap -- '' 1
/usr/local/opt/qt5/libexec/Designer-qt5.app/Contents/MacOS/Designer & disown %%
exit 0
