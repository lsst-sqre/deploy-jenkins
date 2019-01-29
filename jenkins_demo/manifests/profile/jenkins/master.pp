class jenkins_demo::profile::jenkins::master(
  $seed_url = undef,
  $seed_ref = '*/master',
) {
  include ::nginx
  include ::jenkins
  include ::jenkins::master # <- I am a swarm master

  # only required (?) under jdk8
  $alpn = '/usr/lib/jenkins/alpn-boot-8.1.12.v20180117.jar'

  archive { 'alpn-boot-8.1.12.v20180117.jar':
    source  => 'https://repo.maven.apache.org/maven2/org/mortbay/jetty/alpn/alpn-boot/8.1.12.v20180117/alpn-boot-8.1.12.v20180117.jar',
    path    => $alpn,
    cleanup => false,
    extract => false,
    notify  => Class['jenkins::service'],
  }
  -> file { $alpn:
    owner => 'root',
    group => 'root',
    mode  => '0444',
  }

  # exec provider by puppet/yum
  Yumrepo[jenkins] ~> Exec['yum_clean_all']

  # deep merge w/ merge_hash_arrays is incapable of properly merging multiple
  # `- credentails` array of hash elements under:
  #
  # credentials:
  #   system:
  #     domainCredentials:
  #       [- credentials:]
  #
  # as it converts `basicSSHUserPrivateKey` array elements to encapsulated in a
  # hash IF they are not in the base hash but lower down in the hierachy. Yes,
  # this seems crazy, having nested hashes does not appear to be the triggering
  # condition nor not having a similar value to shadow from lower in the
  # hierachy.
  $casc = lookup({
    name       => 'jenkinsx::casc',
    value_type => Hash[String, Any],
  })
  if $casc {

    if $casc['credentials'] and
       $casc['credentials']['system'] and
       $casc['credentials']['system']['domainCredentials'] {
      $dom_creds = $casc['credentials']['system']['domainCredentials']
      $merged_creds = $dom_creds.reduce([]) |Array $result, Hash $value| {
        $result + $value['credentials']
      }
      $real_casc = $casc + {
        credentials => {
          system => {
            domainCredentials => [ credentials => $merged_creds ],
          },
        }
      }
    } else {
      $real_casc = $casc
    }

    # debug -- WILL PRINT SECRETS
    # notice('merged config:')
    # notice(inline_template("<%- require 'json'-%><%= JSON.pretty_generate(@real_casc) %>"))

    file { ['/etc/jenkins', '/etc/jenkins/casc']:
      ensure => directory,
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0750',
    }

    file { '/etc/jenkins/casc/01_config.yaml':
      ensure    => file,
      owner     => 'jenkins',
      group     => 'jenkins',
      mode      => '0640',
      notify    => Class['jenkins::service'],
      content   => to_yaml($real_casc),
      show_diff => false, # likely to contain secrets
      backup    => false,
    }
  }

  #
  # https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+behind+an+NGinX+reverse+proxy
  #
  $access_log          = '/var/log/nginx/jenkins.access.log'
  $error_log           = '/var/log/nginx/jenkins.error.log'
  $private_dir         = '/var/private'
  $ssl_cert_path       = "${private_dir}/cert_chain.pem"
  $ssl_key_path        = "${private_dir}/private.key"
  $ssl_dhparam_path    = "${private_dir}/dhparam.pem"
  $ssl_root_chain_path = "${private_dir}/root_chain.pem"
  $ssl_cert            = lookup('ssl_cert', String, 'first', undef)
  $ssl_chain_cert      = lookup('ssl_chain_cert', String, 'first', undef)
  $ssl_root_cert       = lookup('ssl_root_cert', String, 'first', undef)
  $ssl_key             = lookup('ssl_key', String, 'first', undef)
  $add_header          = lookup('add_header',
                                Hash[String, String], 'first', undef)
  $jenkins_fqdn        = lookup('jenkins_fqdn',
                                String, 'first', $::jenkins_fqdn)

  $proxy_set_header = [
    'Host            $host',
    'X-Real-IP       $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
    'X-Forwarded-Proto https',
  ]

  if ! $ssl_cert and $ssl_key {
    fail('missing tls configuration')
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

  nginx::resource::upstream { 'jenkins':
    ensure  => present,
    members => {
      'localhost:8080' => {
        server => 'localhost',
        port   => 8080,
      },
    },
  }

  # We need to redirect to the canonical https URL in one step.  If we do a
  # http -> https redirect, as is enabled by puppet-nginx's rewrite_to_https
  # param, the the U-A will catch a certificate error before getting to the
  # redirect to the canonical name.
  $http_raw_prepend = [
    "return 301 https://${jenkins_fqdn}\$request_uri;",
  ]
  $https_raw_prepend = [
    "if ( \$host != \'${jenkins_fqdn}\' ) {",
    "  return 301 https://${jenkins_fqdn}\$request_uri;",
    '}',
    "if ( \$http_referer ~ ^(?!https://${jenkins_fqdn}) ) {",
    "  rewrite ^/$ https://${jenkins_fqdn}/blue/organizations/jenkins last;",
    '}',
  ]

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
  }
  -> file { $ssl_dhparam_path:
    ensure   => file,
    mode     => '0400',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
    replace  => false,
    backup   => false,
    notify   => Class['::nginx'],
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
    notify   => Class['::nginx'],
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
    notify    => Class['::nginx'],
  }

  concat { $ssl_root_chain_path:
    ensure   => present,
    mode     => '0444',
    selrange => 's0',
    selrole  => 'object_r',
    seltype  => 'httpd_config_t',
    seluser  => 'system_u',
    backup   => false,
    notify   => Class['::nginx'],
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

  nginx::resource::server { 'jenkins-https':
    ensure                => present,
    listen_port           => 443,
    ssl                   => true,
    access_log            => $access_log,
    error_log             => $error_log,
    ssl_key               => $ssl_key_path,
    ssl_cert              => $ssl_cert_path,
    ssl_dhparam           => $ssl_dhparam_path,
    ssl_session_timeout   => '1d',
    ssl_cache             => 'shared:SSL:50m',
    ssl_stapling          => true,
    ssl_stapling_verify   => true,
    ssl_trusted_cert      => $ssl_root_chain_path,
    resolver              => ['8.8.8.8', '4.4.4.4'],
    proxy                 => 'http://jenkins',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '150',
    proxy_set_header      => $proxy_set_header,
    add_header            => $add_header,
    raw_prepend           => $https_raw_prepend,
    notify                => Class['jenkins::service'],
  }

  # redirect http -> https
  nginx::resource::server { 'jenkins-http':
    ensure               => present,
    listen_port          => 80,
    ssl                  => false,
    access_log           => $access_log,
    error_log            => $error_log,
    raw_prepend          => $http_raw_prepend,
    use_default_location => false,
  }
}
