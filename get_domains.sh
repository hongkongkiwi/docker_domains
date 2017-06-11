#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DEHYDRATED_DOMAINS="/etc/dehydrated/domains.txt"
TEMP_FILE="/tmp/domains.txt"
REMOTE_SCRIPT="${DIR}/remote_docker_domains"
REMOTE_HOST="root@192.168.1.3"
REMOTE_PORT=22
CHECK_DOMAINS_SCRIPT="${DIR}/check_domain.sh"
CHECK_DOMAINS="true"

[[ "$1" == "-v" ]] && DEBUG="true" || DEBUG="false"

command -v md5sum >/dev/null 2>&1 || { echo >&2 "I require md5sum but it's not installed.  Aborting."; exit 1; }
command -v ssh >/dev/null 2>&1 || { echo >&2 "I require ssh but it's not installed.  Aborting."; exit 1; }
command -v sort >/dev/null 2>&1 || { echo >&2 "I require sort but it's not installed.  Aborting."; exit 1; }
command -v uniq >/dev/null 2>&1 || { echo >&2 "I require uniq but it's not installed.  Aborting."; exit 1; }
command -v cat >/dev/null 2>&1 || { echo >&2 "I require cat but it's not installed.  Aborting."; exit 1; }
command -v wc >/dev/null 2>&1 || { echo >&2 "I require wc but it's not installed.  Aborting."; exit 1; }
command -v cut >/dev/null 2>&1 || { echo >&2 "I require cut but it's not installed.  Aborting."; exit 1; }

[ -f "$DEHYDRATED_DOMAINS" ] || { echo >&2 "$DEHYDRATED_DOMAINS does not exist.  Aborting."; exit 2; } 

# Get remote docker VIRTUAL_HOST domains
UNCHECKED_DOMAINS=`ssh -q -p $REMOTE_PORT "$REMOTE_HOST" < "$REMOTE_SCRIPT" | tr " " "\n"`
DOMAINS=""
if [[ "$CHECK_DOMAINS" == "true" ]]; then
  IFS=$'\n'
  for DOMAINS_RAW in $UNCHECKED_DOMAINS
  do
    [[ `echo "$DOMAINS_RAW" | tr -d " "` == "" ]] && continue
    IFS=','
    for DOMAIN in $DOMAINS_RAW
    do
      [[ `echo "$DOMAIN" | tr -d " "` == "" ]] && continue
      CODE=`"$CHECK_DOMAINS_SCRIPT" "$DOMAIN"; echo $?`
      if [ "$CODE" != 0 -a "$CODE" != 255 ]; then
        DOMAINS+="${DOMAIN}\n"
      fi
    done
  done
else
  DOMAINS="$UNCHECKED_DOMAINS"
fi

echo -e "$DOMAINS" | sed '/^\s*$/d' > "$TEMP_FILE"
cat "$DEHYDRATED_DOMAINS" "$TEMP_FILE" | sort | uniq | sed '/^\s*$/d' > "$TEMP_FILE"
cat "$TEMP_FILE" > /dev/null

GET_SUCCESS=$?

[ "$GET_SUCCESS" == "0" ] || { echo >&2 "We could not access the remote domains.  Aborting."; exit 3; }
[ `md5sum "$DEHYDRATED_DOMAINS" | cut -f1 -d " "` == `md5sum "$TEMP_FILE" | cut -f1 -d " "` ] && { [ "$DEBUG" == "true" ] && echo >&2 "No new domains found.  Aborting."; exit 4; }

# Check whether we should update the domains.txt file
if [ -f "$TEMP_FILE" -a \
     `cat "$TEMP_FILE" | wc -l` != "0" -a \
     `md5sum "$DEHYDRATED_DOMAINS" | cut -f1 -d " "` != `md5sum "$TEMP_FILE" | cut -f1 -d " "` ]; then
  [ "$DEBUG" == "true" ] && echo "New domains found! Updating $DEHYDRATED_DOMAINS file"
  cp -R "$TEMP_FILE" "$DEHYDRATED_DOMAINS"
fi
rm "$TEMP_FILE"

exit 0
