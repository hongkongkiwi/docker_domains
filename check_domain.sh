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

[[ "$1" != "" ]] && RESULT=`get_answers_number "$1"` || RESULT=255
exit $RESULT
