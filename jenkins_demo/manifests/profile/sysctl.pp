class jenkins_demo::profile::sysctl(
  Hash $sysctl_hash = undef,
) {
  if $sysctl_hash and !empty($sysctl_hash) {
    create_resources(sysctl, $sysctl_hash, {
      'ensure'   => 'present',
      'provider' => 'augeas',
    })
  }
}
