class jenkins_demo::profile::squash::install {
  # a compiler is needed to build the python mysql bindings
  include ::gcc

  # the 'squash' user only exists to own code to ensure that a running service
  # does not have permission to modify it
  $user    = 'squash'
  $group   = $user
  $base    = '/opt/apps/qa-dashboard'
  $scls    = ['rh-python35']
  $scl_arg = join($scls, ' ')
  $scl_cmd = "scl enable ${scl_arg} --"
  $service = 'uwsgi'

  group { $group:
    gid    => 843,
    system => true,
  }

  user { $user:
    gid        => 843,
    system     => true,
    home       => $base,
    shell      => '/sbin/nologin',
    managehome => false,
  }

  $pkgs = [
    'mariadb-devel',
  ]

  package { $pkgs:
    ensure => present,
  }

  class { 'python':
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
  }

  file { '/opt/apps':
    ensure => directory,
    mode   => '0775',
    owner  => $user,
    group  => $group,
  }

  $production_config = {
    'squash_fqdn'  => $::jenkins_demo::profile::squash::squash_fqdn,
    'bokeh_fqdn'   => $::jenkins_demo::profile::squash::bokeh_fqdn,
    'rds_fqdn'     => $::jenkins_demo::profile::squash::rds_fqdn,
    'rds_password' => $::jenkins_demo::profile::squash::rds_password,
  }

  vcsrepo { $base:
    ensure   => latest,
    provider => git,
    owner    => $user,
    group    => $group,
    source   => $::jenkins_demo::profile::squash::repo,
    revision => $::jenkins_demo::profile::squash::ref,
    require  => File['/opt/apps'],
  } ->
  file { "${base}/squash/squash/settings/production.py":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => epp("${module_name}/squash/production.py.epp", $production_config),
    notify  => Service[$service],
  }

  exec { 'qa-dashboard virtualenv':
    command   => "${scl_cmd} virtualenv venv",
    cwd       => $base,
    user      => $user,
    umask     => '0022',
    creates   => "${base}/venv",
    provider  => 'shell',
    logoutput => true,
    subscribe => Vcsrepo[$base],
    notify    => Service[$service],
    require   => Package[$scls],
  } ~>
  exec { 'qa-dashboard pip/wheel upgrade':
    command     => "${scl_cmd} bash -c 'source venv/bin/activate && pip install --upgrade pip wheel'",
    cwd         => $base,
    user        => $user,
    umask       => '0022',
    provider    => 'shell',
    logoutput   => true,
    refreshonly => true,
    subscribe   => Vcsrepo[$base],
    require     => Package[$scls],
  } ~>
  exec { 'qa-dashboard requirements.txt':
    command     => "${scl_cmd} bash -c 'source venv/bin/activate && pip install --upgrade -r requirements.txt'",
    cwd         => $base,
    user        => $user,
    umask       => '0022',
    provider    => 'shell',
    logoutput   => true,
    refreshonly => true,
    subscribe   => Vcsrepo[$base],
    notify      => Service[$service],
    require     => Package[$scls],
  }
}
