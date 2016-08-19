define jenkins_demo::profile::jenkins::node {
  # puppet-jenkins does not presently support the management of nodes
  # XXX this is a dirty hack

  ensure_resource('file', '/var/lib/jenkins/nodes', {
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0755',
  })

  file { "/var/lib/jenkins/nodes/${title}":
    ensure => directory,
    owner  => 'jenkins',
    group  => 'jenkins',
    mode   => '0755',
  }

  file { "/var/lib/jenkins/nodes/${title}/config.xml":
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0644',
    # the sshslave plugin version shows up in the dump making it non-idempotent
    replace => false,
    content => template("${module_name}/nodes/${title}/config.xml"),
    notify  => Class['jenkins::service'],
  }
}
