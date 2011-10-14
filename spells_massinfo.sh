#!/bin/bash
#---
## by Bor Kraljič <pyrobor[at]ver[dot]si>
## Licence is GPL v2 or higher
##
## Prepares info of spell for bugs or wiki
#---

# let's get sorcery goodies
. /etc/sorcery/config

## mass info from spells

destination=$1

for spell in "$@"; do
  (
   codex_set_current_spell_by_name $spell
   if [[ $destination == "bug" ]]; then
    ########## edit this part
    message "================================"
    message "$SPELL linux 3.0 support check"
    echo ""
    message "Spell *$SPELL* should be checked if it still works properly with linux 3.0.*."
    echo ""
    message "h3. Spell info:"
    echo ""
    message "*SPELL*: $SPELL"
    message "*VERSION*:$VERSION*"
    message "*SHORT*: $SHORT"
    message "*WEB_SITE*: $WEB_SITE"
    message "*current spell files*: source:$SECTION/$SPELL"
    #########
   elif [[ $destination == "wiki" ]]; then
    ########## edit this part
    echo "||$SPELL||$VERSION||$WEB_SITE||source:$SECTION/$SPELL||"
    ##########
   else
    echo "$SPELL - $VERSION"
   fi
  )
done