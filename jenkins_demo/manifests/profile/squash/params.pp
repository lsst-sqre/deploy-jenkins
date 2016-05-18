class jenkins_demo::profile::squash::params {
  $repo            = 'https://github.com/lsst-sqre/qa-dashboard.git'
  $ref             = 'master'
  $squash_fqdn     = $::squash_fqdn
  $bokeh_fqdn      = $::bokeh_fqdn
  #$bokeh_instances = $::processors['count'] * 2
  # XXX running more 1 instance of bokeh is broken.
  # See: https://jira.lsstcorp.org/browse/DM-6104
  $bokeh_instances = 1
  $bokeh_base_port = 5006
  $uwsgi_instances = $::processors['count'] * 2
  $rds_fqdn        = $::rds_fqdn
  $rds_password    = $::rds_password
}
