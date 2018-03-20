class jenkins_demo::role::agent {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::jenkins::agent
  class { 'selinux': mode => 'disabled' }
  include ::jenkins_demo::profile::kernel
  include ::jenkins_demo::profile::kernel::nopti
}
