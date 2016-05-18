class jenkins_demo::profile::squash::bokeh {
  # note that bokeh is using the qa-dashboard virtualenv and is being run as the uwsgi user
  # The virutalenv must be setup and the user account created before the service(s) are started.
  include ::systemd

  $service_config = {
    'squash_fqdn' => $::jenkins_demo::profile::squash::squash_fqdn,
    'bokeh_fqdn'  => $::jenkins_demo::profile::squash::bokeh_fqdn,
  }

  file { '/lib/systemd/system/squash-bokeh@.service':
    ensure  => file,
    mode    => '0644',
    content => epp("${module_name}/squash/squash-bokeh@.service", $service_config),
    notify  => Exec['systemctl-daemon-reload'],
  }

  $end = $::jenkins_demo::profile::squash::bokeh_instances - 1

  range(0, $end).each |$n| {
    $port = $::jenkins_demo::profile::squash::bokeh_base_port + $n

    service { "squash-bokeh@${port}":
      ensure    => running,
      enable    => true,
      subscribe => File['/lib/systemd/system/squash-bokeh@.service'],
    }
  }
}
