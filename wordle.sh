#!/usr/bin/env bash
WORD_FILE=words.txt
WORD_FILE_URL=http://localhost:8000/$WORD_FILE
WORD=$1
PATTERN=$2
AWKS=()
DOTS='....'
LOCAL_FILE=${TMPDIR:-/tmp/}/$WORD_FILE

if [ ! -f "$LOCAL_FILE" ]; then
    curl -s -o "$LOCAL_FILE" $WORD_FILE_URL
fi

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

AWK_CODE=$(echo "${AWKS[@]}" | sed  "s/ / \&\& /g")
awk "$AWK_CODE" "$LOCAL_FILE"

