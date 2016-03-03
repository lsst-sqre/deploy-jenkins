#!/bin/bash

trap 'exit' INT

for d in $(ls -1); do
    if [[ -d $d ]]; then
        vagrant scp master:/var/lib/jenkins/jobs/$d/config.xml $d/config.xml
    fi
done
