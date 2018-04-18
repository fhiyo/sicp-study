#!/usr/bin/env bash
# Author: fhiyo

set -u

# readonly LANGS=(clisp haskell)
# readonly LANG_EXT=(.lisp .hs)
readonly LANGS=(clisp)
readonly LANG_EXT=(.lisp)

usage() {
  echo "Usage: $0 [LANG] OPTIONS [PROBLEM NUMBER]

  LANG:
    ${LANGS[0]}

  OPTIONS:
    -c, --clean                                        Delete all object files and execute files
    -e, --edit         [PROBLEM NUMBER]                Edit source file
    -h, --help                                         Print usage (LANG not needed)
    -l, --lint         [PROBLEM NUMBER]                Check coding style
    -m, --make-env     [PROBLEM NUMBER]                Create need directory and file
    --copy             [PROBLEM NUMBER]                Copy problem code
    -r, --run          [PROBLEM NUMBER]                Execute source code (no input files)
    -a, --all-test     [PROBLEM NUMBER]                Test the program is green or red
    -t, --test         [PROBLEM NUMBER] [TEST NUMBER]  Only run particular test program (specified by [TEST NUMBER])

    -i, --add-input    [PROBLEM NUMBER]                Add input text file
    -o, --add-output   [PROBLEM NUMBER]                Add output text file
  "
}

containsElement () {
  # cf: https://stackoverflow.com/questions/3685970/check-if-a-bash-array-contains-a-value
  declare -r match="$1"
  shift
  for e in "$@"; do
    [[ "${e}" == "${match}" ]] && return 0;
  done
  return 1
}

isexist() {
  if [ $# != 1 ]; then
    echo "Usage: $0 <file or dir path>" 1>&2
    exit 1
  fi
  local path_=$1
  if [ ! -e ${path_} ]; then
    echo "${path_}: No such file or directory" 1>&2
    exit 1
  fi
}

sourcepath() {
  declare -r L=$1
  declare -r PROBLEM=$2

  local iter=0
  for lang_ in "${LANGS[@]}"; do
    if [ ${L} == ${lang_} ]; then
      declare -r SOURCE="src/${L}/${PROBLEM}/${PROBLEM}${LANG_EXT[${iter}]}"
      break
    fi
    (( iter++ ))
  done

  if [ ${iter} -ge ${#LANGS[@]} ]; then
    echo "LANG must be one of the following: \"${LANGS[@]}\"" 1>&2
    exit 1
  fi

  echo ${SOURCE}
}

generateNewTestNumber() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <problem_number> <input/output>" 1>&2
    exit 1
  fi

  declare -r PROBLEM_=$1
  declare -r DIR="test/${PROBLEM_}/$2"

  isexist ${DIR}

  if [[ -z $(ls ${DIR}) ]]; then
    new_test_num=1
  else
    if [[ ${2} == "input" ]]; then
      new_test_num=$(ls ${DIR} | sort -n | tail -1 | xargs -I{} basename {} .lisp)
    elif [[ ${2} == "output" ]]; then
      new_test_num=$(ls ${DIR} | sort -n | tail -1 | xargs -I{} basename {} .txt)
    fi
    (( new_test_num++ ))
  fi
}

addInput() {
  if [ $# != 1 ]; then
    echo "Usage: $0 <problem_number>" 1>&2
    exit 1
  fi

  declare -r PROBLEM=$1
  declare -r INPUT="test/${PROBLEM}/input"

  isexist ${INPUT}
  generateNewTestNumber ${PROBLEM} "input"
  echo -e "(load \"src/clisp/${PROBLEM}/${PROBLEM}.lisp\")\n\n" > ${INPUT}/${new_test_num}.lisp
  vim ${INPUT}/${new_test_num}.lisp
}

addOutput() {
  if [ $# != 1 ]; then
    echo "Usage: $0 <problem_number>" 1>&2
    exit 1
  fi

  declare -r PROBLEM=$1
  declare -r OUTPUT="test/${PROBLEM}/output"

  isexist ${OUTPUT}
  generateNewTestNumber ${PROBLEM} "output"
  vim ${OUTPUT}/${new_test_num}.txt
}

edit() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <LANG> <problem_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2
  declare -r SOURCE=$(sourcepath ${L} ${PROBLEM})
  declare -r DIR=$(dirname ${SOURCE})

  vim ${SOURCE}
}

run() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <LANG> <problem_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2

  declare -r SOURCE=$(sourcepath ${L} ${PROBLEM})

  if [ ${L} == ${LANGS[0]} ]; then
    clisp ${SOURCE}
  else
    echo "LANG must be one of the following: ${LANGS}" 1>&2
    exit 1
  fi
}

test_() {
  if [ $# != 3 ]; then
    echo "Usage: $0 <LANG> <problem_number> <test_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2
  declare -r TEST_NUM=$3

  declare -r INPUT="test/${PROBLEM}/input/${TEST_NUM}.lisp"
  declare -r OUTPUT="test/${PROBLEM}/output/${TEST_NUM}.txt"

  declare -r SOURCE=$(sourcepath ${L} ${PROBLEM})

  isexist ${SOURCE}
  isexist ${INPUT}
  isexist ${OUTPUT}

  cat_command_str="===== cat ${INPUT} ====="
  echo -e "\n${cat_command_str}"
  cat ${INPUT}
  printf '%.s=' $(seq 1 ${#cat_command_str})
  echo -e "\nexpect: $( cat ${OUTPUT} )"
  echo -e "actual: $( clisp ${INPUT} )"
  # NOTE(fhiyo): This is NOT work: "printf '%.s=' {1..${#cat_command_str}}"
  # ref: https://unix.stackexchange.com/questions/7738/how-can-i-use-variable-in-a-shell-brace-expansion-of-a-sequence
  diff <(clisp ${INPUT}) <(cat ${OUTPUT})
  if [ $? != 0 ]; then
    echo -e "test case: $(basename ${INPUT})  --  Condition RED...\n" 1>&2
  else
    echo -e "test case: $(basename ${INPUT})  --  Condition GREEN.\n"
  fi

  if [[ -z $(ls ${INPUT}) ]]; then
    echo -e "\nNot found the test file: ${INPUT}\n"
  fi
}

allTest() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <LANG> <problem_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2

  declare -r INPUT="test/${PROBLEM}/input"
  declare -r OUTPUT="test/${PROBLEM}/output"

  declare -r SOURCE=$(sourcepath ${L} ${PROBLEM})

  isexist ${SOURCE}
  isexist ${INPUT}
  isexist ${OUTPUT}

  i=1
  for test_case in $(ls ${INPUT}); do
    test_ ${L} ${PROBLEM} ${i}
    (( i++ ))
  done
  # for test_case in $(ls ${INPUT}); do
  #   diff <(cat ${INPUT}/${test_case} | run ${L} ${PROBLEM}) <(cat ${OUTPUT}/${test_case})
  #   if [ $? != 0 ]; then
  #     echo -e "test case: ${test_case}  --  Condition RED...\n" 1>&2
  #   else
  #     echo -e "test case: ${test_case}  --  Condition GREEN.\n"
  #   fi
  # done

  if [[ -z $(ls ${INPUT}) ]]; then
    echo -e "\nNo test files.\n"
  else
    echo -e "\nTest end up.\n"
  fi
}

makeEnv() {
  if [ $# != 1 ]; then
    echo "Usage: $0 <program_number>" 1>&2
    exit 1
  fi

  declare -r PROBLEM=$1
  declare -r DIR="src/LANG/${PROBLEM}"
  declare -r INPUT="test/${PROBLEM}/input"
  declare -r OUTPUT="test/${PROBLEM}/output"
  local i=0
  for l in "${LANGS[@]}"; do
    d=${DIR/LANG/${l}}
    mkdir -p ${d}
    (( i++ ))
  done

  mkdir -p ${INPUT} ${OUTPUT}
}

lint() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <LANG> <problem_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2

  declare -r SOURCE=$(sourcepath ${L} ${PROBLEM})

  isexist ${SOURCE}
  if [ ${L} == ${LANGS[0]} ]; then
    echo "Under construction..."
    :
  # elif [ ${L} == ${LANGS[1]} ]; then
  #   hlint ${SOURCE}
  else
    echo "LANG must be one of the following: ${LANGS}" 1>&2
    exit 1
  fi
}

copy() {
  if [ $# != 2 ]; then
    echo "Usage: $0 <LANG> <problem_number>" 1>&2
    exit 1
  fi

  declare -r L=$1
  declare -r PROBLEM=$2
  declare -r SOURCE=$(sourcePath ${L} ${PROBLEM})

  isexist ${SOURCE}
  cat ${SOURCE} | pbcopy
}

clean() {
  # TODO(fhiyo): Use ${LANG} array
  # source_dirs=$(find ./src/{clisp,haskell} -mindepth 1 -maxdepth 1 -type d)
  source_dirs=$(find ./src/{clisp} -mindepth 1 -maxdepth 1 -type d)
  for program_dir in ${source_dirs}; do
    program=$(basename ${program_dir})
    pushd ${program_dir} >/dev/null
    \rm ${program} ${program}.hi ${program}.o 2>/dev/null
    \rm ${program}.lib ${program}.fas 2>/dev/null
    popd > /dev/null
  done
}

### Main

SOURCE_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ $# == 0 ]; then
  usage
  exit 1
fi

# change to directory which this script file exists
# XXX(fhiyo): Work only not exists symbolic link!
cd ${SOURCE_DIR}

containsElement "$1" "${LANGS[@]}"
if [[ $? -eq 0 ]]; then
  readonly lang="$1"
  shift
fi

# analyse optional arguments
for opt in "$@"; do
  # FIXME(fhiyo): invalid argument can pass
  case "${opt}" in
    '-c' | '--clean' )
      clean
      ;;

    '-e' | '--edit' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      edit ${lang} ${prob_number}
      ;;

    '-h' | '--help' )
      usage
      exit 0
      ;;

    '-l' | '--lint' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      lint ${lang} ${prob_number}
      ;;

    '-m' | '--make-env' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      makeEnv ${prob_number}
      ;;

    '--copy' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      copy ${lang} ${prob_number}
      ;;

    '-r' | '--run' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      run ${lang} ${prob_number}
      ;;

    '-a' | '--all-test' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      allTest ${lang} ${prob_number}
      ;;

    '-t' | '--test' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      if [[ -z "${3:-}" ]] || [[ "${3:-}" =~ ^-+ ]]; then
        echo "$0: option requires test number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      test_number="$3"
      shift 3
      test_ ${lang} ${prob_number} ${test_number}
      ;;

    '-i' | '--add-input' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      addInput ${prob_number}
      ;;

    '-o' | '--add-output' )
      if [[ -z "${2:-}" ]] || [[ "${2:-}" =~ ^-+ ]]; then
        echo "$0: option requires problem number as argument -- $1" 1>&2
        exit 1
      fi
      prob_number="$2"
      shift 2
      addOutput ${prob_number}
      ;;

    '*' )
      echo "Invalid argument" 1>&2
      ;;
  esac
done
