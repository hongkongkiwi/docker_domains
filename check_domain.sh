#!/bin/bash

do_query () # name
{
    dig "$1" +noquestion +nostat +noanswer +noauthority 2> /dev/null
}

get_answers_number () # name
{
    local res=$(do_query "$1")
    res=${res##*ANSWER: }
    echo "${res%%,*}"
}

if [[ -f "$1" ]]; then
  DOMAINS=""
  DOMAINS_RAW=`cat "$1"`
  IFS=$'\n'
  for DOMAIN in $DOMAINS_RAW
  do
      if [[ `get_answers_number "$DOMAIN"` == 0 ]]; then
        DOMAINS+="${DOMAIN}\n"
      fi
  done  
  echo -e "$DOMAINS"
else
  [[ "$1" != "" ]] && RESULT=`get_answers_number "$1"` || RESULT=255
  exit $RESULT
fi
