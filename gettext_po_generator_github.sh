#!/bin/bash

    DIR="$1"
    DIRNAME="$1"
    LANGUAGES="bg cs da de el en es et fi fr he hr hu is it ja ko nl no pl pt ro ru sk sv tr uk zh"

    # Detect if folder use subfolder
    [ -d "$DIR/$DIR" ] && DIR="$DIR/$DIR"

    # Folder locale
    [ ! -d $DIR/locale ] && mkdir -p $DIR/locale

    # BKP to compare with diff
    # cp -R $DIR/locale $DIR/locale-old

    # Remove old pot
    [ -e $DIR/locale/$DIRNAME.pot ] && rm $DIR/locale/$DIRNAME.pot
    echo -e "Directory:\t$DIR"

    # Search strings to translate
    for f in $(find $DIR -type f);do

        # Search shell script
        [ "$(file -b --mime-type $f)" != "text/x-shellscript" ] && continue
        [ $(grep 'git' <<< $f) ] && continue

        # Create .pot file
        echo -e "File:\t\t$f"
        bash --dump-po-strings $f >> $DIR/locale/$DIRNAME-tmp.pot

    done

    # Fix pot file
    xgettext --package-name="$DIRNAME" --no-location -L PO -o "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/$DIRNAME-tmp.pot"
    rm $DIR/locale/$DIRNAME-tmp.pot


    # Translate .py files
    # Search strings to translate
    for f in $(find $DIR -type f);do

        # Search shell script
        [ "$(file -b --mime-type $f)" != "text/x-script.python" ] && continue
        [ $(grep 'git' <<< $f) ] && continue

        # Create .pot file
        echo -e "File:\t\t$f"

        sudo apt install python3.10-examples
        /usr/share/doc/python3.10/examples/i18n/pygettext.py -o "$DIR/locale/python.pot" $f
        #/usr/lib/python3.10/Tools/i18n/pygettext.py -o "$DIR/locale/python.pot" $f
        msgcat --no-wrap --strict "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/python.pot" > $DIR/locale/$DIRNAME-tmp.pot
        mv -f "$DIR/locale/$DIRNAME-tmp.pot" "$DIR/locale/$DIRNAME.pot"
        rm -f "$DIR/locale/python.pot"

    done

    # Make pt-BR.po based in .pot
    msgen "$DIR/locale/$DIRNAME.pot" > "$DIR/locale/pt-BR.po"

    # Remove date
    sed -i '/"POT-Creation-Date:/d;/"PO-Revision-Date:/d' $DIR/locale/*

    # Add Subscription-Region support and use brazilsouth
    if [ "$(grep 'Ocp-Apim-Subscription-Region' /usr/local/lib/node_modules/attranslate/dist/services/azure-translator.js)" = "" ]; then
        sudo sed -i '/Ocp-Apim-Subscription-Key/a "Ocp-Apim-Subscription-Region": "brazilsouth",' /usr/local/lib/node_modules/attranslate/dist/services/azure-translator.js
    fi

    # Translate to all $LANGUAGES
    for i  in  $LANGUAGES; do    
        # Translate and make .po
        attranslate --srcFile=$DIR/locale/pt-BR.po --srcLng=pt-BR --srcFormat=po --targetFormat=po --service=azure --serviceConfig=$AZURE_KEY --targetFile=$DIR/locale/$i.po --targetLng=$i --overwriteOutdated=true

        # Make .mo
        LANGUAGE_UNDERLINE="$(echo $i | sed 's|-|_|g')"
        mkdir -p $DIR/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES
        msgfmt "$DIR/locale/$i.po" -o "$DIR/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES/$DIRNAME.mo" || true
        echo "/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES/$DIRNAME.mo"
    done



