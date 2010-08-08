#!/bin/sh

# Because SF URLS are now very (ugly and) diverse, I am writing this script to
# grab the URL.

#Tested with the tintin++, gnome-vfs, and diameter spells.


SPELL=$1
SF_URL="http://sourceforge.net/projects"
SF_DL="http://downloads.sourceforge.net/project"
SF_FILES="http://sourceforge.net/project/$SPELL/files"
#gaze -q where $SPELL

#gaze -q DETAILS gnome-vfs | grep SOURCEFORGE_URL

#grep --include=DETAILS "\$SOURCEFORGE" *

if [ -z "$(gaze -q where $SPELL)" ]; then
#    echo "Spell doesn't exist."
    echo "Spell $SPELL doesn't exist" >> ERRORS
    exit 1
fi


if [ "$(gaze -q DETAILS $SPELL | grep -o '$SOURCEFORGE_URL')" == '$SOURCEFORGE_URL' ]; then
    SOURCE="$(gaze -q sources $SPELL)"
    # The SF unix name is always a lowercase name given to a project, and is a
    # part of all URLS.
    SF_UNIX_NAME="$(gaze source_urls $SPELL | awk -F '/' '{ print $5 }')"
    if [ $? != 0 ]; then
        echo "SF_UNIX_NAME error on $SPELL" >> ERRORS
    fi
    #echo "SF_UNIX_NAME=$SF_UNIX_NAME"
    #echo "Curling...; curl -# "$SF_URL/$SF_UNIX_NAME/files/" | grep -oe "$SF_DL/$F_UNIX_NAME/.*/$SOURCE""
    # Need the slash at end of "files"
    #Only print one of the lines
    echo "$(curl -q "$SF_URL/$SF_UNIX_NAME/files/" | grep -oe "$SF_DL/$SF_UNIX_NAME/.*$SOURCE" | uniq -d)" >> SF_URL_CHANGE

#    echo "Curl exit $?"
    exit 0
else
#    echo "This spell doesn't use a Sourceforge URL."
    echo "$SPELL source = $(gaze source_urls $SPELL)" >> ERRORS
    exit 1
fi