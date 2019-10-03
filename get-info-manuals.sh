#!/usr/bin/env bash

# This script downloads and generates the gcc 8.3 documentation.
# The standalone texinfo files have no Makefile, so some hacks need
#   to be done to generate the info files.

# TODO: bail out if makeinfo not installed

TARBALL=docs-sources.tar.gz

if ! [ -f "$TARBALL" ]; then
  wget https://gcc.gnu.org/onlinedocs/gcc-8.3.0/$TARBALL
  # TODO: exit if failed to download
else
  echo "$TARBALL already found; skipping download"
fi

tar xf "$TARBALL"

DIR=$(readlink -f gcc)
TEXIDIR="$DIR/gcc/doc"

# take the script that generates html, which also happens to generate
# gcc-vers.texi, make that generation permanent by removing a line, and
# put the resulting file in the include directory for convenience
echo -n 'generating gcc-vers.texi... '
(cd "$TEXIDIR";
 sed -e 's/rm $DESTDIR\/gcc-vers.texi//' install.texi2html > gen-vers;
 bash gen-vers >& /dev/null;
 mv HTML/gcc-vers.texi include/)
echo 'done!'

# will access from inside subshell, so need full path here
OUTDIR="$(readlink -f ./gcc-info)"
mkdir -p $OUTDIR

INCLUDE="$TEXIDIR/include"

# assume toplevel texi files all start with '\input texi'
for f in $(find $DIR -name '*.texi'); do
  if head -1 $f | grep '\input texi' > /dev/null; then
    echo -n "compiling top-level $(basename $f)... "
    (cd $(dirname $f);
     makeinfo $f --no-split --force --no-warn -o $OUTDIR -I $INCLUDE)
    echo 'done!'
  fi
done

echo 'ignore "could not find libquadmath-vers.texi" if you see it above'

# the --force is only for libquadmath-vers.texi
# TODO: quotations around bash variables, otherwise might fail with spaced filenames
