#!/usr/bin/env bash

FACTER_pwd=$(pwd) FACTER_group_name=dm FACTER_env_name=prod bundle exec puppet apply --modulepath=$(pwd)/modules --hiera_config=./hiera.yaml ./casc.pp
