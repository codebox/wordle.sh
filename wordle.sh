#!/usr/bin/env bash

WORD_FILE=words.txt
WORD_FILE_URL=http://localhost:8000/$WORD_FILE
AWKS=()
DOTS='....'
LOCAL_FILE=${TMPDIR:-/tmp/}$WORD_FILE

function process_arg {
  WORD=${1:0:5}
  PATTERN=${1:6:5}
  for i in {0..4}; do
  	LETTER=${WORD:$i:1}
  	SYMBOL=${PATTERN:$i:1}
  	TMP_LETTER="${DOTS}${LETTER}${DOTS}"
  	POS_LETTER=${TMP_LETTER:4-i:5}
  	case $SYMBOL in
  		0)
  			AWKS+=("!/${LETTER}/")
  			;;
  		1)
  			AWKS+=("/${LETTER}/" "!/${POS_LETTER}/")
  			;;
  		2)
  			AWKS+=("/${POS_LETTER}/")
  			;;
  	esac
  done
}
for var in "$@"; do
    if [[ "$var" =~ ^[a-z]{5},[012]{5}$ ]]; then
      process_arg "$var"
    else
      echo "Bad argument: '$var' Each argument must be exactly 5 lower-case letters, followed by a comma, followed by 5 of the digits 0,1 or 2"
      exit 1
    fi
done

echo 1
if [ ! -f "$LOCAL_FILE" ]; then
    curl -s -o "$LOCAL_FILE" $WORD_FILE_URL
fi
echo $LOCAL_FILE
AWK_CODE=$(echo "${AWKS[@]}" | sed  "s/ / \&\& /g")
awk "$AWK_CODE" "$LOCAL_FILE"
