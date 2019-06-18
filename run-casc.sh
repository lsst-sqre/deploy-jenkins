#!/bin/bash

FACTER_group_name=dm FACTER_env_name=jhoblitt-curly FACTER_role=master FACTER_jenkins_fqdn=jhoblitt-curly-ci.lsst.codes FACTER_domain_name=lsst.codes \
    bundle exec puppet apply --hiera_config="$(pwd)/hiera.yaml" casc.pp
