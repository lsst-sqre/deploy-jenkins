class jenkins_demo::role::squash {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::squash
  include ::jenkins_demo::profile::squash::install
  include ::jenkins_demo::profile::squash::bokeh
  include ::jenkins_demo::profile::squash::uwsgi

  Class['jenkins_demo::profile::squash::install'] ~>
    Class['jenkins_demo::profile::squash::uwsgi']

  Class['jenkins_demo::profile::squash::install'] ~>
    Class['jenkins_demo::profile::squash::bokeh']

  Class['jenkins_demo::profile::squash::uwsgi'] ->
    Class['jenkins_demo::profile::squash::bokeh']

  class { 'selinux': mode => 'permissive' }
}
