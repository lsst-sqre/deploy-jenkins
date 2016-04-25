class jenkins_demo::profile::squash::uwsgi {
  $user = 'uwsgi'
  $group = $user

  $pkgs = [
    'uwsgi',
    'uwsgi-plugin-common',
    'uwsgi-plugin-python',
    'uwsgi-logger-systemd',
  ]

  group { $group:
    gid    => 678,
    system => true,
  }

  user { $user:
    gid        => 678,
    system     => true,
    home       => '/run/uwsgi',
    shell      => '/sbin/nologin',
    managehome => false,
  }

  package { $pkgs:
    ensure => present,
  }

  $service_config = {
    'instances' => $::jenkins_demo::profile::squash::uwsgi_instances,
  }

  file { '/etc/uwsgi.d/squash.ini':
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => epp("${module_name}/squash/squash.ini.epp", $service_config),
    require => Package[$pkgs],
  }

  # needed in order for nginx to access the unix domain socket
  selinux::module { 'squash-uwsgi-sock':
    ensure  => 'present',
    content => epp("${module_name}/squash/squash.te.epp"),
  }

  service { 'uwsgi':
    ensure  => running,
    enable  => true,
    require => [
      Package[$pkgs],
      File['/etc/uwsgi.d/squash.ini'],
    ],
  }
}
