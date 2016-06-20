#!/bin/bash

trap 'exit' INT

if [[ $# -eq 0 ]]; then
  jobs=$(ls -1)
else
  jobs=$*
fi

for d in $jobs; do
  if [[ -d "$d" ]]; then
    vagrant scp "master:/var/lib/jenkins/jobs/$d/config.xml" "$d/config.xml"
  fi
done
