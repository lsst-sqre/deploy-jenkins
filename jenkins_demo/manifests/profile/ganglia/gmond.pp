class jenkins_demo::profile::ganglia::gmond {
  $www_host = hiera('www_host', 'jenkins-master')

  $udp_recv_channel = [
    {port  => 8649, bind => 'localhost'},
    {port  => 8649, bind => '0.0.0.0'},
  ]
  $udp_send_channel = [
    {port  => 8649, host => 'jenkins-master', ttl => 2},
  ]
  $tcp_accept_channel = [
    {port => 8649},
  ]

  class { '::ganglia::gmond':
    cluster_name                   => 'jenkins',
    cluster_owner                  => 'Large Synoptic Suvery Telescope',
    cluster_latlong                => 'N32.2332147 W110.9481163',
    cluster_url                    => $www_host,
    host_location                  => 'Amazon Web Services',
    udp_recv_channel               => $udp_recv_channel,
    udp_send_channel               => $udp_send_channel,
    tcp_accept_channel             => $tcp_accept_channel,
    globals_host_dmax              => '86400',
    globals_send_metadata_interval => '60',
    globals_override_hostname      => $::hostname,
  }
}
