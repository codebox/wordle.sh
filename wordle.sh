#!/usr/bin/env bash

WORD_FILE=words.txt
WORD_FILE_DIR=words
WORD_FILE_URL=http://localhost:8000/$WORD_FILE
SUGGESTION_COUNT=10
AWKS=()
LOCAL_FILE="${WORD_FILE_DIR}/${WORD_FILE}"
INSTRUCTIONS=$(cat <<-END
=====================
=-  WORDLE SOLVER  -=
=====================
Usage: $0 [--count=<suggestions>] <word>,<result> (<word>,<result> ...)
  * suggestions: maximum number of matching words to display (default is ${SUGGESTION_COUNT})
  * <word>:      five letter word that you guessed
  * <result>:    five letters indicating the result that you got from Wordle:
    > b: Black square (letter does not appear in word)
    > y: Yellow square (letter appears in another position)
    > g: Green square (letter appears in this position)

Example: $0 crane,bygbb stair,bbgby
END
)

function tolower {
  echo $1 | tr '[:upper:]' '[:lower:]'
}
function process_arg {
  WORD=$(tolower ${1:0:5})
  PATTERN=$(tolower ${1:6:5})
  while read UNIQUE_LETTER
  do
    BLACK_COUNT=0
    YELLOW_COUNT=0
    GREEN_COUNT=0
    POSITIONS=''
    for i in {0..4}; do
      THIS_LETTER=${WORD:$i:1}
      THIS_SYMBOL=${PATTERN:$i:1}
      THIS_POSITION="."
      if [[ "$UNIQUE_LETTER" = "$THIS_LETTER" ]]; then
        case $THIS_SYMBOL in
          b)
            ((BLACK_COUNT = BLACK_COUNT + 1))
            THIS_POSITION="[^${UNIQUE_LETTER}]"
            ;;
          y)
            ((YELLOW_COUNT = YELLOW_COUNT + 1))
            THIS_POSITION="[^${UNIQUE_LETTER}]"
            ;;
          g)
            ((GREEN_COUNT = GREEN_COUNT + 1))
            THIS_POSITION="${UNIQUE_LETTER}"
            ;;
        esac
      fi
      POSITIONS="${POSITIONS}${THIS_POSITION}"
    done
    ((TOTAL_COUNT = YELLOW_COUNT + GREEN_COUNT))
    REPETITION=""
    if [[ $TOTAL_COUNT -eq 0 ]]; then
      AWKS+=("!/${UNIQUE_LETTER}/")
    else
      if [[ $BLACK_COUNT -eq 0 ]]; then
        REPETITION=","
      fi
      AWKS+=("/([^${UNIQUE_LETTER}]*${UNIQUE_LETTER}){${TOTAL_COUNT}${REPETITION}}/")
    fi
    if [[ $TOTAL_COUNT -gt 0 ]]; then
      AWKS+=("/${POSITIONS}/")
    fi
  done < <(echo $WORD | grep -o . | sort -u)
}

for var in "$@"; do
    if [[ "$var" =~ ^[A-Za-z]{5},[bygBYG]{5}$ ]]; then
      process_arg "$var"
    elif [[ "$var" =~ ^--count=[0-9]+$ ]]; then
      SUGGESTION_COUNT=${var:8}
    else
      echo "Bad argument: '$var'"
      exit 1
    fi
done

if [[ ${#AWKS[@]} -eq 0 ]] ; then
    echo "$INSTRUCTIONS"
    exit 0
fi

if [ ! -f "$LOCAL_FILE" ]; then
  echo "Downloading ${WORD_FILE}..."
  mkdir -p "$WORD_FILE_DIR"
  curl -s -o "$LOCAL_FILE" $WORD_FILE_URL
fi

AWK_CODE=$(echo "${AWKS[@]}" | sed  "s/ / \&\& /g")
POSSIBILITIES=$(awk "$AWK_CODE" "$LOCAL_FILE")
SUGGESTIONS=$(echo "$POSSIBILITIES" | tail -${SUGGESTION_COUNT} | tr '\n' ' ' | tr '[:lower:]' '[:upper:]')
MATCH_COUNT=$(echo "$POSSIBILITIES" | grep -c . )

if [[ $MATCH_COUNT -eq 0 ]]; then
  echo "No valid matches found, maybe check your arguments?"
elif [[ $MATCH_COUNT -eq 1 ]]; then
  echo "The only match is $SUGGESTIONS"
else
  echo $SUGGESTIONS
  echo "[${MATCH_COUNT} matches found in total]"
fi  
