
# args: filed_separator, header, row_0, row_1 .. row_N
# header and each row is single string of fields separted by filed separator
# provided as first argument
# header fields can have formatting options
#  * : group by column (note data MUST be odered by that column)
#  < : left align (default)
#  > : right align
#  - : TODO center align
# e.g. print_table ";" "h1*<;h2;h3>" "g1;val 1,1;val 1,2" "g1;val 2,1;val 2,2" "g2;val 3,1;val 3,2"
# will print:
#  | h1 | h2      |      h3 |
#  |----+---------+---------|
#  | g1 | val 1,1 | val 1,2 |
#  |    | val 2,1 | val 2,2 |
#  |----+---------+---------|
#  | g2 | val 3,1 | val 3,2 |
function print_table() {
  local field_sep=';'
  shift
  local row_count=${#}
  local rows=("${@}")

  IFS=${field_sep} read -r -a header <<< "${rows[0]}"
  local col_count="${#header[@]}"
  declare -a col_align
  # parse header to get initial col widths and formatting
  declare -a col_width
  local group_column=-1
  local i
  for ((i=0;i<col_count;i++)); do
    local h=${header[${i}]}
    # get header name by stripping formatting
    local name=${h%%[<>*]*}
    # get format dierctives
    local frmt=${h:${#name}}
    header[${i}]=${name}
    col_width[${i}]=${#name}
    if [[ -n "${frmt}" ]];then
      if [[ ${frmt} == *'*'* ]];then
        group_column=${i}
      fi
      if [[ ${frmt} == *'>'* ]];then
        col_align[${i}]=""
      else
        col_align[${i}]="-"
      fi
    else
      col_align[${i}]="-"
    fi
  done
  # iterate over all rows to find max width for each column
  for ((i=1;i<row_count;i++)); do
    IFS=${field_sep} read -r -a fields <<< "${rows[${i}]}"
    local j
    for ((j=0;j<col_count;j++)); do
      if [[ ${col_width[${j}]} -lt ${#fields[${j}]} ]]; then
        col_width[${j}]=${#fields[${j}]}
      fi
    done
  done

  local row_fmt="|"
  for ((i=0;i<col_count;i++)); do
    row_fmt="${row_fmt} %${col_align[${i}]}${col_width[${i}]}.${col_width[${i}]}s |"
  done

  # build divider
  local div="|-$(printf "%${col_width[0]}s" | tr " " "-")-"
  for ((i=1;i<col_count;i++)); do
    div="${div}+-$(printf "%${col_width[${i}]}s" | tr " " "-")-"
  done
  div="${div}|"

  # print header
  printf "${row_fmt}\n" "${header[@]}"
  if [[ ${group_column} -lt 0 ]];then
    echo "${div}"
  fi

  local current_group=""
  for ((i=1;i<row_count;i++)); do
    IFS=${field_sep} read -r -a fields <<< "${rows[${i}]}"
    if [[ ${group_column} -ge 0 ]];then
      if [[ ${fields[${group_column}]} != ${current_group} ]];then
        echo "${div}"
        current_group=${fields[${group_column}]}
      else
        fields[${group_column}]=""
      fi
    fi
    printf "${row_fmt}\n" "${fields[@]}"
  done
}
