#!/bin/bash

# Captura a língua original ou define 'en-US' como padrão
OriginalLang=${OriginalLang:-'en'}

DIR="$1"
DIRNAME="$1"
LANGUAGES="bg cs da de el en es et fi fr he hr hu is it ja ko nl no pl pt ro ru sk sv tr uk zh"
# LANGUAGES="pt de es fr"

if [ -z "$OPENAI_KEY" ];then
    red='\e[31;1m'
    neg='\e[37;1m'
    std='\e[m'
    echo -e "${red}Atualize o workflow de tradução.\nO exemplo se encontra em \"https://github.com/biglinux/biglinux-package-with-translate/blob/main/.github/workflows/translate-and-build-package.yml\" ${std}"
    echo
    echo -e "${red}Atualize o workflow de tradução.\nO exemplo se encontra em \"https://github.com/biglinux/biglinux-package-with-translate/blob/main/.github/workflows/translate-and-build-package.yml\" ${std}"
    echo -e "${red}Atualize o workflow de tradução.\nO exemplo se encontra em \"https://github.com/biglinux/biglinux-package-with-translate/blob/main/.github/workflows/translate-and-build-package.yml\" ${std}"
    echo
    echo -e "${red}Atualize o workflow de tradução.\nO exemplo se encontra em \"https://github.com/biglinux/biglinux-package-with-translate/blob/main/.github/workflows/translate-and-build-package.yml\" ${std}"
    sleep infinity
fi

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
for f in $(find $DIR \( -path "*/.git" -o -path "*/.github" \) -prune -o -type f);do

    # Search shell script
    [ "$(file -b --mime-type $f)" != "text/x-shellscript" ] && continue
    [ $(grep 'git' <<< $f) ] && continue

    # Create .pot file
    echo -e "File:\t\t$f"
    bash --dump-po-strings $f >> $DIR/locale/$DIRNAME-tmp.pot
    [ "$?" != "0" ] && exit 1
done

# Fix pot file
xgettext --package-name="$DIRNAME" --no-location -L PO -o "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/$DIRNAME-tmp.pot"
rm $DIR/locale/$DIRNAME-tmp.pot


npm install -g stonejs-tools
wget https://raw.githubusercontent.com/biglinux/stonejs-tools/master/src/extract.js -O /usr/local/lib/node_modules/stonejs-tools/src/extract.js

# Search HTML and JS
HTML_JS_FILES=$(find $DIR -type f \( -name "*.html" -o -name "*.js" \))

if [ -n "$HTML_JS_FILES" ]; then
    stonejs extract $HTML_JS_FILES $DIR/locale/$DIRNAME-tmp.pot

    # Method 1
    #     # update .po from strings HTML/JS
    #     for po_file in $DIR/locale/*.po; do
    #         stonejs update $po_file $DIR/locale/$DIRNAME.pot
    #     done

    # Method 2
    #    pushd $DIR/locale/
    #    stonejs update *.po $DIRNAME.pot
    #    popd

    # Method 3 Fix pot file
    xgettext --package-name="$DIRNAME" --no-location -L PO -o "$DIR/locale/$DIRNAME-js.pot" -i "$DIR/locale/$DIRNAME-tmp.pot"
    rm $DIR/locale/$DIRNAME-tmp.pot

    # Combine files from bash and js/html
    if [[ -e "$DIR/locale/$DIRNAME-js.pot" ]]; then
        if [[ -e "$DIR/locale/$DIRNAME.pot" ]]; then
            mv "$DIR/locale/$DIRNAME.pot" "$DIR/locale/$DIRNAME-bash.pot"
            msgcat --no-wrap --strict "$DIR/locale/$DIRNAME-bash.pot" -i "$DIR/locale/$DIRNAME-js.pot" > $DIR/locale/$DIRNAME-tmp.pot
            xgettext --package-name="$DIRNAME" --no-location -L PO -o "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/$DIRNAME-tmp.pot"
            rm "$DIR/locale/$DIRNAME-bash.pot"
            rm "$DIR/locale/$DIRNAME-js.pot"
        else
            mv "$DIR/locale/$DIRNAME-js.pot" "$DIR/locale/$DIRNAME.pot"
        fi
    fi
fi

# Translate .py files
# Install .py dependencies
sudo pip install python-gettext
# Search strings to translate
for f in $(find $DIR \( -path "*/.git" -o -path "*/.github" \) -prune -o -type f);do

    # Search python script
    [ "$(file -b --mime-type $f)" != "text/x-script.python" ] && continue
    [ $(grep 'git' <<< $f) ] && continue

    # Create .pot file
    echo -e "File:\t\t$f"
    pygettext3 -o "$DIR/locale/python.pot" $f
    #/usr/lib/python3.10/Tools/i18n/pygettext.py -o "$DIR/locale/python.pot" $f
    msgcat --no-wrap --strict "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/python.pot" > $DIR/locale/$DIRNAME-tmp.pot
    xgettext --package-name="$DIRNAME" --no-location -L PO -o "$DIR/locale/$DIRNAME.pot" -i "$DIR/locale/$DIRNAME-tmp.pot"
#     [ "$?" != "0" ] && exit 1
    rm -f "$DIR/locale/python.pot"
done

# Make original lang based in .pot
msgen "$DIR/locale/$DIRNAME.pot" > "$DIR/locale/$OriginalLang.po"

# Remove date
sed -i '/"POT-Creation-Date:/d;/"PO-Revision-Date:/d' $DIR/locale/*

# # Add Subscription-Region support and use brazilsouth
# if [ "$(grep 'Ocp-Apim-Subscription-Region' /usr/local/lib/node_modules/attranslate/dist/services/azure-translator.js)" = "" ]; then
#     sudo sed -i '/Ocp-Apim-Subscription-Key/a "Ocp-Apim-Subscription-Region": "brazilsouth",' /usr/local/lib/node_modules/attranslate/dist/services/azure-translator.js
# fi

# sudo sed -i '/temperature:/s/temperature:.*/temperature: 0,/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js
# sudo sed -i 's/Translate the following text from ${args.srcLng} to ${args.targetLng}/please dont interact, just translate this word or phrase, if you only have one word, just answer me the translation of that word, dont write the original word, translate from ${args.srcLng} to ${args.targetLng}:/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js
# sudo sed -i 's/gpt-3.5-turbo-instruct/gpt-3.5-turbo-0125/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js
# sudo sed -i 's/openai.createCompletion/openai.createChatCompletion/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js
# sudo sed -i 's/completion.data.choices[0].text/chatCompletion.data.choices[0].message/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js

# sudo sed -i 's/Translate the following text from ${args.srcLng} into ${args.targetLng}:/only translate my software string from ${args.srcLng} to ${args.targetLng}. dont chat or explain. Using the correct terms for computer software in the target language, only show target language never repeat string. if you dont find something to translate, dont respond, string:/' /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js


# cat /usr/local/lib/node_modules/attranslate/dist/services/openai-translate.js

for i in $LANGUAGES; do
    if [ "$i" != "$OriginalLang" ]; then
        attranslate --srcFile=$DIR/locale/$OriginalLang.po --srcLng=$OriginalLang --srcFormat=po --targetFormat=po --service=openai --serviceConfig=$OPENAI_KEY --targetFile=$DIR/locale/$i.po --targetLng=$i
    fi

    sed -i '/Content-Type: text\/plain;/s/charset=.*\\/charset=utf-8\\/' $DIR/locale/$i.po

    # Make .mo
    LANGUAGE_UNDERLINE="$(echo $i | sed 's|-|_|g')"
    mkdir -p $DIR/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES
    # Make json translations
    if [[ -e "$DIR/locale/$i.po" ]]; then
        stonejs build --format=json --merge "$DIR/locale/$i.po" "$DIR/locale/$i.json"
        sed -i "s|^{\"$i\"|{\"$DIR\"|g;s|^{\"C\"|{\"$i\"|g" "$DIR/locale/$i.json"
    else
        rm -f "$DIR/locale/$i.json"
    fi
    cp "$DIR/locale/$i.json" "$DIR/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES/$DIRNAME.json"
    msgfmt "$DIR/locale/$i.po" -o "$DIR/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES/$DIRNAME.mo" || true
#     [ "$?" != "0" ] && exit 1
    echo "/usr/share/locale/$LANGUAGE_UNDERLINE/LC_MESSAGES/$DIRNAME.mo"

#     sleep 2
done


