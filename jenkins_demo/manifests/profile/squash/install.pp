class jenkins_demo::profile::squash::install {
  # a compiler is needed to build the python mysql bindings
  include ::gcc

  # the 'squash' user only exists to own code to ensure that a running service
  # does not have permission to modify it
  $user = 'squash'
  $group = $user
  $base = '/opt/apps/qa-dashboard'

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
    require  => [Package[$pkgs], File['/opt/apps']],
  } ->
  file { "${base}/squash/squash/settings/production.py":
    ensure  => file,
    owner   => $user,
    group   => $group,
    mode    => '0644',
    content => epp("${module_name}/squash/production.py.epp", $production_config),
  }

  python::virtualenv { $base:
    ensure       => present,
    version      => 'system',
    requirements => "${base}/requirements.txt",
    venv_dir     => "${base}/venv",
    owner        => $user,
    group        => $group,
    cwd          => $base,
    timeout      => 0,
    require      => Class['gcc'],
    subscribe    => Vcsrepo[$base], # update if clone changes
  }
}
