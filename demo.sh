#!/usr/bin/env bash

base_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")

source ${base_dir}/asciitable.sh

printf "\nSimple table\n\n"

print_table ';'           \
  "h0;h1;h2"              \
  "[0, 0];[0, 1];[0, 2]"  \
  "[1, 0];[1, 1];[1, 2]"  \
  "[2, 0];[2, 1];[2, 2]"  \
  "[3, 0];[3, 1];[3, 2]"


printf "\n\nGroup column\n\n"

print_table ";"       \
  "h0*;h1;h2"         \
  "g0;[0, 1];[0, 2]"  \
  "g0;[1, 1];[1, 2]"  \
  "g1;[2, 1];[2, 2]"  \
  "g1;[2, 1];[2, 2]"  \
  "g1;[3, 1];[3, 2]"


printf "\n\nText alignment\n\n"

print_table ";"           \
  "h0*;left<;right>"      \
  "[0, 0];[0, 1];[0, 2]"  \
  "[1, 0];[1, 1];[1, 2]"  \
  "[2, 0];[2, 1];[2, 2]"  \
  "[3, 0];____[3, 1]____;____[3, 2]____"
