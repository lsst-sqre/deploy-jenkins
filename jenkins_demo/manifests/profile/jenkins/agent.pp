class jenkins_demo::profile::jenkins::agent(
  Enum['normal', 'exclusive'] $slave_mode          = 'normal',
  Optional[Variant[Array[String], String]] $labels = undef,
  Boolean                      $use_default_labels = true,
  Integer                               $executors = 1,
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
    }
    # this isn't nessicary with puppet/archive 1.x
    -> file { $dockergc:
      mode => '0555',
    }

    cron { 'docker-gc':
      command => $dockergc,
      minute  => '0',
      hour    => '4',
    }
    Class[::jenkins::slave] -> Class[::docker]
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

  class { 'jenkins::slave':
    masterurl  => 'http://jenkins-master:8080',
    slave_name => $::hostname,
    slave_home => '/j',
    slave_mode => $slave_mode,
    executors  => $executors,
    labels     => join(delete_undef_values($real_labels), ' '),
  }

  # provides killall on el6 & el7
  ensure_packages(['psmisc'])
  ensure_packages(['lsof'])
  # unzip is needed my packer-newintsall
  ensure_packages(['unzip'])
}
