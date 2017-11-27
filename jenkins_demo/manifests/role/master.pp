class jenkins_demo::role::master {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::ganglia::web
  include ::jenkins_demo::profile::master
  class { 'selinux': mode => 'enforcing' }
  include ::jenkins_demo::profile::kernel
}
