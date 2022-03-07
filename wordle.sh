#!/usr/bin/env bash

WORD_FILE=words.txt
WORD_FILE_URL=http://localhost:8000/$WORD_FILE
AWKS=()
LOCAL_FILE=${TMPDIR:-/tmp/}$WORD_FILE

function process_arg {
  WORD=${1:0:5}
  PATTERN=${1:6:5}
  while read UNIQUE_LETTER
  do
    ZERO_COUNT=0
    ONE_COUNT=0
    TWO_COUNT=0
    POSITIONS=''
    for i in {0..4}; do
      THIS_LETTER=${WORD:$i:1}
      THIS_SYMBOL=${PATTERN:$i:1}
      THIS_POSITION="."
      if [[ "$UNIQUE_LETTER" = "$THIS_LETTER" ]]; then
        case $THIS_SYMBOL in
          0)
            ((ZERO_COUNT = ZERO_COUNT + 1))
            ;;
          1)
            ((ONE_COUNT = ONE_COUNT + 1))
            THIS_POSITION="[^${UNIQUE_LETTER}]"
            ;;
          2)
            ((TWO_COUNT = TWO_COUNT + 1))
            THIS_POSITION="${UNIQUE_LETTER}"
            ;;
        esac
      fi
      POSITIONS="${POSITIONS}${THIS_POSITION}"
    done
    ((FINAL_COUNT = ONE_COUNT + TWO_COUNT))
    REPETITION=""
    if [[ $FINAL_COUNT -eq 0 ]]; then
      AWKS+=("!/${UNIQUE_LETTER}/")
    else
      if [[ $ZERO_COUNT -eq 0 ]]; then
        REPETITION=","
      fi
      AWKS+=("/([^${UNIQUE_LETTER}]*${UNIQUE_LETTER}){${FINAL_COUNT}${REPETITION}}/")
    fi
    if [[ $FINAL_COUNT -gt 0 ]]; then
      AWKS+=("/${POSITIONS}/")
    fi
  done < <(echo $WORD | grep -o . | sort -u)
}

for var in "$@"; do
    if [[ "$var" =~ ^[a-z]{5},[012]{5}$ ]]; then
      process_arg "$var"
    else
      echo "Bad argument: '$var' Each argument must be exactly 5 lower-case letters, followed by a comma, followed by 5 of the digits 0,1 or 2"
      exit 1
    fi
done

if [ ! -f "$LOCAL_FILE" ]; then
    curl -s -o "$LOCAL_FILE" $WORD_FILE_URL
fi

AWK_CODE=$(echo "${AWKS[@]}" | sed  "s/ / \&\& /g")
awk "$AWK_CODE" "$LOCAL_FILE"
echo $AWK_CODE