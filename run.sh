#!/bin/sh -

set -euf

modname=VGG_ILSVRC_19_layers.caffemodel
model=models/"$modname"
url="https://www.dropbox.com/s/fey1erjccf0brkb/$modname?dl=1"
digest=b5c644beabd7cf06bdd9065cfd674c97
size=574671192

gpu=-1
luajit=./bin/luajit
torch=./lib/luarocks/rocks/trepl/scm-1/bin/th
script=./share/lua/5.1/neural_style.lua

luainit="\
local k, l, _ = pcall(require, 'luarocks.loader') \
_ = k and l.add_context('trepl', 'scm-1')"

tab="$(printf "\t.")"; tab="${tab%.}"
eol="$(printf "\n.")"; eol="${eol%.}"
ifs=" $tab$eol"; IFS="$ifs"

prog="${0##*/}"
cwd="$(pwd)"
pid=$$

check_model ()
{
	test -f "$model" &&
	test $(/usr/bin/stat -f %z "$model") -eq $size &&
	test $(/sbin/md5 -r < "$model") = $digest
}

isabs ()
{
	case "$1" in (/*) ;; (*) false ;; esac
}

hsize ()
(
	n=${1:-0} u=${2:-1024} p=${3:-3} i=0 r=0 U=${4:-BKMGTPEZY}
	while test $n -ge $u && test $i -lt ${#U}; do
		r=$((n % u))
		n=$((n / u))
		i=$((i + 1))
	done
	r=$(printf %03d $((r * 1000 / u)))
	l=$((p - ${#n})) x=""
	while test $l -gt 0; do
		y="${r#?}"
		x="$x${r%"$y"}"
		r="$y"
		l=$((l - 1))
	done
	n=$(printf %d.%s $n $x)
	while true; do
		case "$n" in
			(*.*0) n="${n%0}" ;;
			(*) break ;;
		esac
	done
	t="$U"
	while test $i -gt 0; do
		t="${t#?}"
		i=$((i - 1))
	done
	n="${n%.}${t%"${t#?}"}"
	printf "%s\n" "${n%B}"
)

ord ()
{
	printf %d "'$1"
}

getkey ()
{
	eval ${1:-key}=$(
		export LANG=C LC_ALL=C
		key="" attr=$(/bin/stty -g)
		trap -- '/bin/stty "$attr"' 0 1 2 15
		/bin/stty -brkint -icrnl -inpck -istrip -ixon -opost -parenb \
			cs8 -echo -icanon -iexten -isig cs8 time 1 min 0
		while test x"$key" = x; do
			IFS="" read -r key || true
		done
		ord "$key"
	)
}

yesno ()
{
	if test $# -gt 0; then
		fmt="$1"; shift
		printf -- "$fmt" "$@" 1>&2
	fi
	while true; do
		getkey key
		case "$key" in
			(89|121)	echo Yes; return 0 ;;
			(110|78)	echo No; return 1 ;;
			(113|81|4)	echo Quit; exit 1 ;;
			(3)		kill -2 $pid; exit 130 ;;
			(*)		tput bel || true ;;
		esac
	done
}

chkmod=true fixnext=false gpunext=false argv="" comp=0
for arg in "$@"; do
	skip=false
	if $gpunext; then
		gpunext=false gpu="$arg" skip=true
	elif $fixnext; then
		fixnext=false
		isabs "$arg" || arg="$cwd"/"$arg"
	else
		case "$arg" in
			(-n|-no-fetch|--no-fetch) chkmod=false skip=true ;;
			(-h|-help|--help) chkmod=false argv=-h gpu=""; break ;;
			(-*_image)
				fixnext=true
				case "$arg" in
					(-style_image)		add=1 ;;
					(-content_image)	add=2 ;;
					(-output_image)		add=4 ;;
					(*)			add=0 ;;
				esac
				comp=$((comp | add))
				;;
			(-*_file) fixnext=true chkmod=false ;;
			(-gpu) gpunext=true skip=true ;;
		esac
	fi
	$skip || argv="$argv$arg$eol"
done
test $comp -eq 7 || argv=-h

IFS="$eol"; set -- ${gpu:+-gpu$eol$gpu} $argv; IFS="$ifs"

cd -- "$(case "$0" in (*/*) cd -- "${0%/*}" ;; esac && pwd)" || exit

if	$chkmod && ! check_model &&
	yesno "Model not found. Download (%s) [y/n/q]? " $(hsize $size); then
	/usr/bin/curl -L "$url" 1>"$model" || true
	if ! check_model; then
		printf "error: failed to fetch model from %s\n" "$url"
		exit 127
	fi
fi

exec /usr/bin/env \
	LUA_PATH="./share/lua/5.1/?.lua;./share/lua/5.1/?/init.lua" \
	LUA_CPATH="./lib/lua/5.1/?.so;./lib/?.dylib" \
	DYLD_LIBRARY_PATH=./lib \
	"$luajit" ${luainit:+-e "$luainit"} \
	"$torch" "$script" "$@"
