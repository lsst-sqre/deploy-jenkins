class jenkins_demo::profile::squash::uwsgi {
  include ::systemd

  $user    = 'uwsgi'
  $group   = $user
  $base    = '/opt/uwsgi'
  $scl     = 'rh-python35'
  $scl_cmd = "scl enable ${scl} --"
  $service = 'uwsgi'

  $pkgs = [
    'jansson-devel',
    'libattr-devel',
    'libcap-devel',
    'libevent-devel',
    'libuuid-devel',
    'libxml2-devel',
    'libxslt-devel',
    'openssl-devel',
    'pcre-devel',
    'zlib-devel',
    'xz-libs',
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

  ensure_packages($pkgs)

  vcsrepo { $base:
    ensure   => latest,
    provider => 'git',
    owner    => $user,
    group    => $group,
    source   => 'https://github.com/unbit/uwsgi.git',
    revision => '2.0.14',
  } ->
  exec { 'build uwsgi core':
    command   => "${scl_cmd} python uwsgiconfig.py --build core",
    cwd       => $base,
    umask     => '0022',
    creates   => "${base}/uwsgi",
    provider  => 'shell',
    logoutput => true,
    notify    => Service[$service],
    require   => [
      Package[$pkgs],
      Package[$scl],
    ],
  } ->
  exec { 'build uwsgi python plugin':
    command   => "${scl_cmd} python uwsgiconfig.py --plugin plugins/python core",
    cwd       => $base,
    umask     => '0022',
    creates   => "${base}/python_plugin.so",
    provider  => 'shell',
    logoutput => true,
    notify    => Service[$service],
    require   => [
      Package[$pkgs],
      Package[$scl],
    ],
  }

  $service_config = {
    'instances' => $::jenkins_demo::profile::squash::uwsgi_instances,
  }

  file { '/etc/uwsgi.d':
    ensure => directory,
    mode   => '0755',
  }

  file { '/etc/uwsgi.d/squash.ini':
    ensure  => file,
    owner   => $user,
    group   => $user,
    mode    => '0644',
    content => epp("${module_name}/squash/squash.ini.epp", $service_config),
    notify  => Service[$service],
  }

  file { '/etc/uwsgi.ini':
    ensure  => file,
    mode    => '0644',
    content => epp("${module_name}/squash/uwsgi.ini.epp"),
    notify  => Service[$service],
  }

  # needed in order for nginx to access the unix domain socket
  # XXX this is not needed when uwsgi is listening on an ip socket
  #selinux::module { 'squash-uwsgi-sock':
  #  ensure  => 'present',
  #  content => epp("${module_name}/squash/squash.te.epp"),
  #}

  systemd::unit_file { "${service}.service":
    content => epp("${module_name}/squash/${service}.service.epp",
      { path => $base }),
    notify  => Service[$service],
  }

  service { $service:
    ensure  => running,
    enable  => true,
    require => [
      Package[$pkgs],
    ],
  }
}
