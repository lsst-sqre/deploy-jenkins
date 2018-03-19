class jenkins_demo::profile::jenkins::agent(
  Enum['normal', 'exclusive'] $slave_mode          = 'normal',
  Optional[Variant[Array[String], String]] $labels = undef,
  Boolean                      $use_default_labels = true,
) {
  if $::operatingsystemmajrelease == '7' {
    include ::docker

    $docker = 'docker'
    $dockergc = '/usr/local/bin/docker-gc'

    archive { 'docker-gc':
      source  => 'https://raw.githubusercontent.com/spotify/docker-gc/master/docker-gc',
      path    => $dockergc,
      cleanup => false,
      extract => false,
    } ->
    # this isn't nessicary with puppet/archive 1.x
    file { $dockergc:
      mode => '0555',
    }

    cron { 'docker-gc':
      command => $dockergc,
      minute  => '0',
      hour    => '4',
    }
    Class[::docker] -> Class[::jenkins::slave]
  } else {
    $docker = undef
  }

  $default_labels = [
    $::hostname,
    downcase($::os['name']),
    downcase("${::os['name']}-${::os['release']['major']}"),
    $docker,
  ]

  if ($use_default_labels) {
    $real_labels = concat($default_labels, $labels)
  } else {
    $real_labels = $labels
  }

  notice($real_labels)
  class { 'jenkins::slave':
    masterurl    => 'http://jenkins-master:8080',
    slave_name   => $::hostname,
    slave_groups => $docker,
    slave_mode   => $slave_mode,
    executors    => 1,
    labels       => join(delete_undef_values($real_labels), " "),
    # don't start slave before lsstsw build env is ready
    require      => [
      Host['jenkins-master'],
    ],
  }

  # This is nessicary to ensure that the rvm group is created before the
  # jenkins-slave service is started while avoiding a dependency loop with the
  # jenkins-slave user resource.
  Rvm::System_user['jenkins-slave'] -> Service['jenkins-slave']

  # provides killall on el6 & el7
  ensure_packages(['psmisc'])
  ensure_packages(['lsof'])
  # unzip is needed my packer-newintsall
  ensure_packages(['unzip'])

  # virtualenv is needed by validate_drp
  class { 'python':
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
  }
}
