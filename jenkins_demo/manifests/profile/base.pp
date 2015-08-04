class jenkins_demo::profile::base {
  include ::augeas
  include ::sysstat
  include ::irqbalance
  include ::ntp

  host { 'jenkins-master':
    ensure => 'present',
    ip     => '192.168.123.10',
  }

  class { 'timezone': timezone  => 'US/Pacific' }
  class { 'tuned': profile      => 'virtual-host' }
  class { 'firewall': ensure    => 'stopped' }
  resources { 'firewall': purge => true }

  if $::osfamily == 'RedHat' {
    if $::operatingsystem != 'Fedora' {
      include ::epel
      Class['epel'] -> Package<| provider != 'rpm' |>
    }

    # note:
    #   * el6.x will update everything
    #   * the jenkins package is only present on the master
    class { '::yum_autoupdate':
      exclude      => ['kernel*', 'jenkins'],
      notify_email => false,
      action       => 'apply',
      update_cmd   => 'security',
    }
  }

  # only needed for debugging
  class { '::ruby::dev':
    bundler_ensure => 'latest',
  }
  ensure_packages(['git'])
}
