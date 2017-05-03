class jenkins_demo::role::slave {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::slave
  class { 'selinux': mode => 'disabled' }
  include ::jenkins_demo::profile::devtoolset_3
  include ::jenkins_demo::profile::devtoolset_4
  include ::jenkins_demo::profile::devtoolset_6
}
