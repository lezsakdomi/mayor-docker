#!/bin/bash
source $MAYORDIR/update/linkme.sh
POLICIES="parent public"
BASEDIR="$MAYORDIR"

for POLICY in $POLICIES; do
  eval "LIST=\$${POLICY}Link"
  for f in $LIST; do
      DIR=`echo $f | cut -d / -f 1-2`
      if [ ! -d $BASEDIR/www/policy/$POLICY/$DIR ]; then
          echo "    Könyvtár: $BASEDIR/www/policy/$POLICY/$DIR"
          mkdir -p $BASEDIR/www/policy/$POLICY/$DIR || exit 255
      else
          echo "    [OK] A könyvtár már létezik: $MAYORDIR/www/policy/$POLICY/$DIR"
      fi
      FILES="$f-pre.php $f.php"
      for file in $FILES; do
          if [ ! -e $BASEDIR/www/policy/$POLICY/$file ]; then
              if [ -f $BASEDIR/www/policy/private/$file ]; then
                  echo "      $BASEDIR/www/policy/private/$file --> $BASEDIR/www/policy/$POLICY/$file"
                  ln -s $BASEDIR/www/policy/private/$file $BASEDIR/www/policy/$POLICY/$file || exit 255
              else
                  echo "      Hiányzó file: $BASEDIR/www/policy/private/$file" >&2
		  #exit 255
              fi
          else
              echo "      [OK] A file már létezik: $BASEDIR/www/policy/private/$file"
          fi
      done
  done
done
