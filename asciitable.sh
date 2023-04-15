
# args: filed_separator, header, row_0, row_1 .. row_N
# header and each row is single string of fields separted by filed separator
# provided as first argument
# fields can use ANSI escape code get colour output 
# see: https://en.wikipedia.org/wiki/ANSI_escape_code
# e.g. to get green text set value: \e[38;5;76mGREEN TEXT\e[0m
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
  local field_sep=${1}
  shift
  local row_count=${#}
  local rows=("${@}")

  # parse header to get initial col widths and formatting
  IFS=${field_sep} read -r -a header <<< "${rows[0]}"
  local col_count="${#header[@]}"
  declare -a col_width
  declare -a col_align
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
  # also collect field data width info i.e. width of data without escape sequences
  # color escape
  local color_esc=$(printf '%b' '\e')
  local color_re='(.*)\\e(\[[0-9;]+m)(.*)'
  # for each row holds info field raw text width (after removing color escape sequnces)
  declare -a field_widths_rows
  for ((i=1;i<row_count;i++)); do
    IFS=${field_sep} read -r -a fields <<< "${rows[${i}]}"
    local row_esc=
    local width_row=
    local j
    for ((j=0;j<col_count;j++)); do
      local field_esc=${fields[${j}]}
      local field=${fields[${j}]}
      while [[ ${field} =~ ${color_re} ]]; do
        field=${BASH_REMATCH[1]}${BASH_REMATCH[3]}
      done
      while [[ ${field_esc} =~ ${color_re} ]]; do
        field_esc=${BASH_REMATCH[1]}${color_esc}${BASH_REMATCH[2]}${BASH_REMATCH[3]}
      done
      if [[ j -gt 0 ]]; then
        width_row="${width_row};"
        row_esc="${row_esc}${field_sep}"
      fi
      width_row="${width_row}${#field}"
      row_esc="${row_esc}${field_esc}"
      # keep track of column max width, take into account length witout any escape sequences
      if [[ ${col_width[${j}]} -lt ${#field} ]]; then
        col_width[${j}]=${#field}
      fi
    done
    rows[${i}]=${row_esc}
    field_widths_rows[${i}]="${width_row}"
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

  #  use separator as uninitialized value for group as can't be valid value
  local current_group=${field_sep} 
  for ((i=1;i<row_count;i++)); do
    IFS=${field_sep} read -r -a fields <<< "${rows[${i}]}"
    IFS=';' read -r -a field_widths <<< "${field_widths_rows[${i}]}"

    if [[ ${group_column} -ge 0 ]];then
      if [[ ${fields[${group_column}]} != ${current_group} ]];then
        echo "${div}"
        current_group=${fields[${group_column}]}
      else
        fields[${group_column}]=""
      fi
    fi

    row_fmt="|"
    for ((j=0;j<col_count;j++)); do
      local width
      if [[ ${j} -eq ${group_column} && ${fields[${group_column}]} == "" ]]; then
        width=${col_width[${j}]}
      else
        width=${col_width[${j}]}
        local field_esc_width=${#fields[${j}]}
        local field_width=${field_widths[${j}]}
        if [[ ${field_esc_width} != ${field_width} ]];then
            width=$((field_esc_width+width-field_width))
        fi
      fi
      row_fmt="${row_fmt} %${col_align[${j}]}${width}.${width}s |"
    done
    printf "${row_fmt}\n" "${fields[@]}"
  done
}
