class jenkins_demo::profile::squash(
  $repo            = $::jenkins_demo::profile::squash::params::repo,
  $ref             = $::jenkins_demo::profile::squash::params::ref,
  $squash_fqdn     = $::jenkins_demo::profile::squash::params::squash_fqdn,
  $bokeh_fqdn      = $::jenkins_demo::profile::squash::params::bokeh_fqdn,
  $bokeh_instances = $::jenkins_demo::profile::squash::params::bokeh_instances,
  $bokeh_base_port = $::jenkins_demo::profile::squash::params::bokeh_base_port,
  $uwsgi_instances = $::jenkins_demo::profile::squash::params::uwsgi_instances,
  $rds_fqdn        = $::jenkins_demo::profile::squash::params::rds_fqdn,
  $rds_password    = $::jenkins_demo::profile::squash::params::rds_password,
  $oauth_config    = $::jenkins_demo::profile::squash::params::oauth_config,
) inherits jenkins_demo::profile::squash::params {
  include ::nginx
  # el7 ships with py2.7
  include ::jenkins_demo::profile::scl::python35

  $squash_access_log   = '/var/log/nginx/squash.access.log'
  $squash_error_log    = '/var/log/nginx/squash.error.log'
  $bokeh_access_log    = '/var/log/nginx/bokeh.access.log'
  $bokeh_error_log     = '/var/log/nginx/bokeh.error.log'
  $private_dir         = '/var/private'
  $ssl_cert_path       = "${private_dir}/cert_chain.pem"
  $ssl_key_path        = "${private_dir}/private.key"
  $ssl_dhparam_path    = "${private_dir}/dhparam.pem"
  $ssl_root_chain_path = "${private_dir}/root_chain.pem"
  $ssl_cert            = hiera('ssl_cert', undef)
  $ssl_chain_cert      = hiera('ssl_chain_cert', undef)
  $ssl_root_cert       = hiera('ssl_root_cert', undef)
  $ssl_key             = hiera('ssl_key', undef)
  $add_header          = hiera('add_header', undef)
  #$uwsgi_sock          = 'unix:/run/uwsgi/squash.sock'
  #=> 'unix:/home/vagrant/qa-dashboard/squash/squash.sock',
  $base                = '/opt/apps/qa-dashboard'

  $proxy_set_header = [
    'Host              $host',
    'X-Real-IP         $remote_addr',
    'X-Forwarded-For   $proxy_add_x_forwarded_for',
    'Upgrade           $http_upgrade',
    'Connection        "upgrade"',
    'X-Forwarded-Proto $scheme',
  ]

  unless $ssl_cert and $ssl_key {
    fail('tls cert and private key are required')
  }

  if $::selinux {
    selboolean { 'httpd_can_network_connect':
      value      => on,
      persistent => true,
    }

    selboolean { 'httpd_setrlimit':
      value      => on,
      persistent => true,
    }
  }

  # If SSL is enabled and we are catching an DNS cname, we need to redirect to
  # the canonical https URL in one step.  If we do a http -> https redirect, as
  # is enabled by puppet-nginx's rewrite_to_https param, the the U-A will catch
  # a certificate error before getting to the redirect to the canonical name.
  $squash_raw_prepend = [
    "if ( \$host != \'${squash_fqdn}\' ) {",
    "  return 301 https://${squash_fqdn}\$request_uri;",
    '}',
  ]

  $bokeh_raw_prepend = [
    "if ( \$host != \'${bokeh_fqdn}\' ) {",
    "  return 301 https://${bokeh_fqdn}\$request_uri;",
    '}',
  ]

  $end = $bokeh_instances - 1

  $bokeh_members = range(0, $end).reduce([]) |Array $memo, Integer $n| {
    $port = $bokeh_base_port + $n
    $memo + "127.0.0.1:${port}"
  }

  nginx::resource::upstream { 'qa-dashboard':
    ensure  => present,
    members => [ '127.0.0.1:9090' ],
  }

  nginx::resource::upstream { 'qa-dashboard-oauth':
    ensure  => present,
    members => [ '127.0.0.1:4180' ],
  }

  nginx::resource::upstream { 'squash-bokeh':
    ensure               => present,
    members              => $bokeh_members,
    upstream_cfg_prepend => { ip_hash => '' },
  }

  nginx::resource::upstream { 'squash-bokeh-oauth':
    ensure  => present,
    members => [ '127.0.0.1:4181' ],
  }

  file { $private_dir:
    ensure   => directory,
    mode     => '0750',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
  }

  exec { 'openssl dhparam -out dhparam.pem 2048':
    path    => ['/usr/bin'],
    cwd     => $private_dir,
    umask   => '0433',
    creates => $ssl_dhparam_path,
  } ->
  file { $ssl_dhparam_path:
    ensure   => file,
    mode     => '0400',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
    replace  => false,
    backup   => false,
  }

  # note that nginx needs the signed cert and the CA chain in the same file
  concat { $ssl_cert_path:
    ensure   => present,
    mode     => '0444',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
    backup   => false,
    before   => Class['::nginx'],
  }
  concat::fragment { 'public - signed cert':
    target  => $ssl_cert_path,
    order   => 1,
    content => $ssl_cert,
  }
  concat::fragment { 'public - chain cert':
    target  => $ssl_cert_path,
    order   => 2,
    content => $ssl_chain_cert,
  }

  file { $ssl_key_path:
    ensure    => file,
    mode      => '0400',
    selrange  => 's0',
    selrole   => 'object_r',
    seltype   => 'httpd_config_t',
    seluser   => 'system_u',
    content   => $ssl_key,
    backup    => false,
    show_diff => false,
    before    => Class['::nginx'],
  }

  concat { $ssl_root_chain_path:
    ensure   => present,
    mode     => '0444',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
    backup   => false,
    before   => Class['::nginx'],
  }
  concat::fragment { 'root-chain - chain cert':
    target  => $ssl_root_chain_path,
    order   => 1,
    content => $ssl_chain_cert,
  }
  concat::fragment { 'root-chain - root cert':
    target  => $ssl_root_chain_path,
    order   => 2,
    content => $ssl_root_cert,
  }

  nginx::resource::vhost { 'squash-https':
    ensure                => present,
    server_name           => [ $squash_fqdn ],
    listen_port           => 443,
    ssl                   => true,
    rewrite_to_https      => false,
    access_log            => $squash_access_log,
    error_log             => $squash_error_log,
    ssl_key               => $ssl_key_path,
    ssl_cert              => $ssl_cert_path,
    ssl_dhparam           => $ssl_dhparam_path,
    ssl_session_timeout   => '1d',
    ssl_cache             => 'shared:SSL:50m',
    ssl_stapling          => true,
    ssl_stapling_verify   => true,
    ssl_trusted_cert      => $ssl_root_chain_path,
    resolver              => [ '8.8.8.8', '4.4.4.4'],
    #uwsgi                => $uwsgi_sock,
    proxy                 => 'http://qa-dashboard-oauth',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '30',
    proxy_set_header      => $proxy_set_header,
    add_header            => $add_header,
    raw_prepend           => $squash_raw_prepend,
  }

  # XXX this is to work around jfryman/nginx adding 300 to the priority of the
  # concat fragments used to construct the ssl vhost template.  The default
  # priority of 500 works with a non-ssl vhost but ends up the before the
  # server {} block of an ssl host.  Inversly, a priority of 800-899 ends up
  # after the server {} block of a non-ssl host.
  $priority = 850

  nginx::resource::vhost { 'squash-http':
    ensure                => present,
    server_name           => [ $squash_fqdn ],
    listen_port           => 80,
    ssl                   => false,
    rewrite_to_https      => true,
    access_log            => $squash_access_log,
    error_log             => $squash_error_log,
    #uwsgi                => $uwsgi_sock,
    proxy                 => 'http://qa-dashboard-oauth',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '30',
    proxy_set_header      => $proxy_set_header,
    # see comment above $raw_prepend declaration
    raw_prepend           => $squash_raw_prepend,
  }

  nginx::resource::location { '~ ^.*/api':
    ensure                => present,
    priority              => $priority,
    vhost                 => 'squash-https',
    proxy                 => 'http://qa-dashboard',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '30',
  }

  nginx::resource::location { '/static':
    ensure         => present,
    priority       => $priority,
    vhost          => 'squash-https',
    location_alias => "${base}/squash/static",
    index_files    => [], # disable
  }

  nginx::resource::location { '/static/rest_framework':
    ensure         => present,
    priority       => $priority,
    vhost          => 'squash-https',
    # XXX this is horrible -- need a front end static asset manager
    location_alias => "${base}/venv/lib/python3.5/site-packages/rest_framework/static/rest_framework",
    index_files    => [], # disable
  }

  nginx::resource::location { '/favico.ico':
    ensure      => present,
    priority    => $priority,
    vhost       => 'squash-https',
    www_root    => "${base}/squash",
    index_files => [], # disable
  }

  nginx::resource::vhost { 'bokeh-https':
    ensure                => present,
    server_name           => [ $bokeh_fqdn ],
    listen_port           => 443,
    ssl                   => true,
    rewrite_to_https      => false,
    access_log            => $bokeh_access_log,
    error_log             => $bokeh_error_log,
    ssl_key               => $ssl_key_path,
    ssl_cert              => $ssl_cert_path,
    ssl_dhparam           => $ssl_dhparam_path,
    ssl_session_timeout   => '1d',
    ssl_cache             => 'shared:SSL:50m',
    ssl_stapling          => true,
    ssl_stapling_verify   => true,
    ssl_trusted_cert      => $ssl_root_chain_path,
    resolver              => [ '8.8.8.8', '4.4.4.4'],
    proxy                 => 'http://squash-bokeh-oauth',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '30',
    proxy_set_header      => $proxy_set_header,
    raw_prepend           => $bokeh_raw_prepend,
    add_header            => $add_header,
    location_raw_append   => @("EOT"/$)
      if ( \$remote_addr ~* '${::squash_ip}' ) {
        proxy_pass            http://squash-bokeh;
      }
    |EOT
  }

  nginx::resource::vhost { 'bokeh-http':
    ensure                => present,
    server_name           => [ $bokeh_fqdn ],
    listen_port           => 80,
    ssl                   => false,
    access_log            => $bokeh_access_log,
    error_log             => $bokeh_error_log,
    rewrite_to_https      => true,
    proxy                 => 'http://squash-bokeh-oauth',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '30',
    proxy_set_header      => $proxy_set_header,
    raw_prepend           => $bokeh_raw_prepend,
  }

  nginx::resource::location { 'bokeh /static':
    ensure         => present,
    location       => '/static',
    priority       => $priority,
    vhost          => 'bokeh-https',
    # XXX this is horrible -- need a front end static asset manager
    location_alias => "${base}/venv/lib/python3.5/site-packages/bokeh/server/static",
    index_files    => [], # disable
  }
}
