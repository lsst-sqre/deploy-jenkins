#!/bin/bash

trap 'exit' INT

if [[ $# -eq 0 ]]; then
  jobs=$(find . -name config.xml)
else
  jobs=$*
fi

for c in $jobs; do
  if [[ -e "$c" ]]; then
    vagrant scp "master:/var/lib/jenkins/jobs/$c" "$c"
  fi
done
