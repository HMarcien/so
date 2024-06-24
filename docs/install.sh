#!/usr/bin/env bash

set -eu

help() {
  cat <<'EOF'
Install a binary release of `so` hosted on GitHub

Usage:
    install [options]

Options:
    -h, --help      Display this message
    -f, --force     Force overwriting an existing binary
    --tag TAG       Tag (version) of the crate to install (default <latest release>)
    --to LOCATION   Where to install the binary (default ~/.cargo/bin)
EOF
}

git=samtay/so
crate=so
url=https://github.com/samtay/so
releases=$url/releases

case "$(uname -s)" in
  "Darwin")
    platform="apple-darwin" ;;
  "Linux")
    platform="unknown-linux-musl" ;;
  *)
    platform="pc-windows-msvc";;
esac

target="$(uname -m)-$platform"

say() {
  echo "install: $1"
}

say_err() {
  say "$1" >&2
}

err() {
  if [ ! -z ${td-} ]; then
    rm -rf $td
  fi

  say_err "ERROR $1"
  exit 1
}

need() {
  if ! command -v $1 > /dev/null 2>&1; then
    err "need $1 (command not found)"
  fi
}

force=false
while test $# -gt 0; do
  case $1 in
    --force | -f)
      force=true
      ;;
    --help | -h)
      help
      exit 0
      ;;
    --tag)
      tag=$2
      shift
      ;;
    --to)
      dest=$2
      shift
      ;;
    *)
      ;;
  esac
  shift
done

# Dependencies
need basename
need curl
need install
need mkdir
need mktemp
need tar

# Optional dependencies
if [ -z ${tag-} ]; then
  need cut
  need rev
fi

if [ -z ${dest-} ]; then
  dest="$HOME/.cargo/bin"
fi

if [ -z ${tag-} ]; then
  tag=$(
    curl --silent "https://api.github.com/repos/samtay/so/releases/latest" |
      grep '"tag_name":' |
      sed -E 's/.*"([^"]+)".*/\1/'
  )
fi

archive="$releases/download/$tag/$crate-$target.tar.gz"

say_err "Repository:  $url"
say_err "Crate:       $crate"
say_err "Tag:         $tag"
say_err "Target:      $target"
say_err "Destination: $dest"
say_err "Archive:     $archive"

# Check if binary exists
if [ "$(curl --head --write-out "%{http_code}\n" --silent --output /dev/null "$archive")" -eq "404" ]; then
  err "The binary you need does not exist; you can build the crate from source or open an issue requesting the target: $target"
fi

td=$(mktemp -d || mktemp -d -t tmp)
curl -sL $archive | tar -C $td -xz

for f in $(ls $td); do
  test -x $td/$f || continue

  if [ -e "$dest/$f" ] && [ $force = false ]; then
    err "$f already exists in $dest; use --force to overwrite it"
  else
    mkdir -p $dest
    install -m 755 $td/$f $dest
  fi
done

rm -rf $td
