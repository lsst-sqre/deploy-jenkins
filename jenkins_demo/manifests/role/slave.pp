class jenkins_demo::role::slave {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::slave
}
