class jenkins_demo::profile::kernel::nopti() {
  kernel_parameter { 'nopti':
    ensure => present,
  }
  ~> reboot { 'pti':
    apply   => finished,
    message => 'disabling kernel pti',
    when    => refreshed,
  }
}
