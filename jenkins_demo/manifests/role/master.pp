class jenkins_demo::role::master {
  include ::jenkins_demo::profile::base
  include ::jenkins_demo::profile::ganglia::gmond
  include ::jenkins_demo::profile::ganglia::web
  include ::jenkins_demo::profile::jenkins::master
  # run a jnlp agent to execute jobs that need to be bound to the
  # jenkins-master node (E.g., backups).  This provides some priviledge
  # separation between the master process and the builds as they will be
  # executed under the jenkins-slave user instead of the jenkins user.
  include ::jenkins_demo::profile::jenkins::agent
  class { 'selinux': mode => 'enforcing' }
  include ::jenkins_demo::profile::kernel
  include ::jenkins_demo::profile::kernel::pquota
}
