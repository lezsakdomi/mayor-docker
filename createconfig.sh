#!/bin/bash -e

if [ "$MAYORDIR" = "" ]; then echo "A MAYORDIR változó üres. Kilépek."; exit 1; fi
PWGEN=`which pwgen`
if [ "${PWGEN}" = "" ]; then echo "A pwgen szoftver nincs telepítve."; exit 1; fi

echo "Konfigurációs állományok létrehozása:"
for file in main-config.php parent-conf.php private-conf.php public-conf.php
do
    if [ -e "${MAYORDIR}/config/${file}" ]; then echo "  $file létezik."; else
	echo -n "  $file.example --> "
	PW=`pwgen -s1`
	cat "$MAYORDIR/config/$file.example" | sed s/%SQLPW%/$PW/ > "$MAYORDIR/config/$file"
	echo $file
    fi
done

echo -n "  module-naplo/config.php.example --> "
PW=`pwgen -s1`
PWREAD=`pwgen -s1`
if [ -e "$MAYORDIR/config/module-naplo/config.php" ]; then echo "  module-naplo/config.php létezik."; else
    cat "$MAYORDIR/config/module-naplo/config.php.example" | sed -e s/%SQLPW%/$PW/ -e s/%SQLPWREAD%/$PWREAD/ > "$MAYORDIR/config/module-naplo/config.php"
    echo "module-naplo/config.php"
fi

if [ -e "$MAYORDIR/config/skin-classic/naplo-config.php" ]; then echo "  skin-classic/naplo-config.php létezik."; else
    echo -n "  skin-classic/naplo-config.php.example --> "
    cp $MAYORDIR/config/skin-classic/naplo-config.php.example $MAYORDIR/config/skin-classic/naplo-config.php
    echo "config/skin-classic/naplo-config.php"
fi
