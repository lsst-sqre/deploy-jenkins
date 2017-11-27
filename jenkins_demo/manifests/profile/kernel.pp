class jenkins_demo::profile::kernel(
  $version,
) {

  package { [
    "kernel-${version}",
    "kernel-headers-${version}",
  ]:
    ensure => present,
    notify => Reboot['kernel version'],
  }

  # sanity check booted kernel
  unless ($::kernelrelease == $version) {
    notify { "system is running ${::kernelrelease}, desrired version is ${version}":
      notify => Reboot['kernel version'],
    }
  }

  reboot { 'kernel version':
    apply   => finished,
    message => 'changing running kernel',
    when    => refreshed,
  }
}
