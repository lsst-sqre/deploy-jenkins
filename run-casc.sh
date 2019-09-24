#!/usr/bin/env bash

export FACTER_pwd
FACTER_pwd=$(pwd)
export FACTER_group_name=dm
export FACTER_env_name=prod

bundle exec puppet apply --modulepath="$(pwd)/modules" --hiera_config=./hiera.yaml ./casc.pp
