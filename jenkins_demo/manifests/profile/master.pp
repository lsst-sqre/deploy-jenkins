class jenkins_demo::profile::master {
  include ::wget # needed by jenkins
  include ::nginx

  Class['::wget'] -> Class['::jenkins']
  # lint:ignore:arrow_alignment
  class { 'jenkins':
    configure_firewall => false,
    cli                => true,
    executors          => 0,
    config_hash        => {
      'JENKINS_LISTEN_ADDRESS' => { 'value' => '' },
      'JENKINS_HTTPS_PORT'     => { 'value' => '' },
      'JENKINS_AJP_PORT'       => { 'value' => '-1' },
    },
  }
  # lint:endignore
  include ::jenkins::master # <- I am a swarm master

  # run a jnlp slave to execute jobs that need to be bound to the
  # jenkins-master node (E.g., backups).  This provides some priviledge
  # separation between the master process and the builds as they will be
  # executed under the jenkins-slave user.  jenkins user.
  class { 'jenkins::slave':
    masterurl    => 'http://jenkins-master:8080',
    executors    => 1,
    slave_mode   => 'exclusive',
    install_java => false,
  }

  jenkins::job { 'stack-os-matrix':
    config => template("${module_name}/jobs/stack-os-matrix/config.xml"),
  }

  $jenkins_ebs_snapshot = hiera('jenkins::jobs::jenkins_ebs_snapshot', undef)
  if $jenkins_ebs_snapshot {
    class { 'python' :
      version    => 'system',
      pip        => true,
      dev        => true,
      virtualenv => true,
    }
    jenkins::job { 'jenkins-ebs-snapshot':
      config => template("${module_name}/jobs/jenkins-ebs-snapshot/config.xml"),
    }
  }

  jenkins::plugin { 'github': }
    jenkins::plugin { 'git': }
      jenkins::plugin { 'scm-api': }
      jenkins::plugin { 'git-client': }
    jenkins::plugin { 'github-api': }

  jenkins::plugin { 'github-oauth':
    source => 'https://s3-us-west-2.amazonaws.com/github-oauth-plugin/github-oauth.hpi',
  }
    jenkins::plugin { 'mailer': }
    #jenkins::plugin { 'github-api': }
    #jenkins::plugin { 'git': }

  jenkins::plugin { 'nodelabelparameter': }
    jenkins::plugin { 'token-macro': }
    jenkins::plugin { 'jquery': }
    jenkins::plugin { 'parameterized-trigger': }

  $hipchat = hiera('jenkins::plugins::hipchat', undef)

  if $hipchat {
    $hipchat_xml = 'jenkins.plugins.hipchat.HipChatNotifier.xml'
    jenkins::plugin { 'hipchat':
      manage_config   => true,
      config_filename => $hipchat_xml,
      config_content  => template("${module_name}/plugins/${hipchat_xml}"),
    }
  }

  jenkins::plugin { 'postbuildscript': }
    #jenkins::plugin { 'mailer': }
    jenkins::plugin { 'maven-plugin': }
    jenkins::plugin { 'javadoc': }

  jenkins::plugin { 'greenballs': }

  $ansicolor_xml = 'hudson.plugins.ansicolor.AnsiColorBuildWrapper.xml'
  jenkins::plugin { 'ansicolor':
    manage_config   => true,
    config_filename => $ansicolor_xml,
    config_content  => template("${module_name}/plugins/${ansicolor_xml}"),
  }

  $collapsing_xml = 'org.jvnet.hudson.plugins.collapsingconsolesections.CollapsingSectionNote.xml'
  jenkins::plugin { 'collapsing-console-sections':
    manage_config   => true,
    config_filename => $collapsing_xml,
    config_content  => template("${module_name}/plugins/${collapsing_xml}"),
  }

  jenkins::plugin { 'rebuild': }

  jenkins::plugin { 'build-user-vars-plugin': }

  jenkins::plugin { 'envinject': }

  jenkins::plugin { 'purge-build-queue-plugin': }
    #jenkins::plugin { 'maven-plugin': }

  #
  # https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+behind+an+NGinX+reverse+proxy

  $access_log          = '/var/log/nginx/jenkins.access.log'
  $error_log           = '/var/log/nginx/jenkins.error.log'
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
  $www_host            = hiera('www_host', 'jenkins-master')

  $proxy_set_header = [
    'Host            $host',
    'X-Real-IP       $remote_addr',
    'X-Forwarded-For $proxy_add_x_forwarded_for',
  ]

  if $ssl_cert and $ssl_key {
    $enable_ssl = true
  }

  selboolean { 'httpd_can_network_connect':
    value      => on,
    persistent => true,
  }

  selboolean { 'httpd_setrlimit':
    value      => on,
    persistent => true,
  }

  nginx::resource::upstream { 'jenkins':
    ensure  => present,
    members => [
      'localhost:8080',
    ],
  }

  # If SSL is enabled and we are catching an DNS cname, we need to redirect to
  # the canonical https URL in one step.  If we do a http -> https redirect, as
  # is enabled by puppet-nginx's rewrite_to_https param, the the U-A will catch
  # a certificate error before getting to the redirect to the canonical name.
  $raw_prepend = [
    "if ( \$host != \'${www_host}\' ) {",
    '  return 301 https://citest.lsst.codes$request_uri;',
    '}',
  ]

  if $enable_ssl {
    file { $private_dir:
      ensure => directory,
      mode   => '0700',
    }

    exec { 'openssl dhparam -out dhparam.pem 2048':
      path    => ['/usr/bin'],
      cwd     => $private_dir,
      umask   => '0400',
      creates => $ssl_dhparam_path,
    }

    # note that nginx needs the signed cert and the CA chain in the same file
    concat { $ssl_cert_path:
      ensure => present,
      mode   => '0444',
      backup => false,
      before => Class['::nginx'],
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
      content   => $ssl_key,
      backup    => false,
      show_diff => false,
      before    => Class['::nginx'],
    }

    concat { $ssl_root_chain_path:
      ensure => present,
      mode   => '0444',
      backup => false,
      before => Class['::nginx'],
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

    nginx::resource::vhost { 'jenkins':
      ensure                => present,
      listen_port           => 443,
      ssl                   => true,
      rewrite_to_https      => false,
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
      resolver              => [ '8.8.8.8', '4.4.4.4'],
      proxy                 => 'http://jenkins',
      proxy_redirect        => 'default',
      proxy_connect_timeout => '150',
      proxy_set_header      => $proxy_set_header,
      add_header            => $add_header,
      raw_prepend           => $raw_prepend,
    }
  }

  # If ssl is enabled, the ssl vhost takes the resource name 'jenkins' so that
  # any nginx::resource::location resources in other profiles (E.g.
  # jenkins_demo::profile::ganglia::web) will inject into the primary vhost.
  $vhost = $enable_ssl ? {
    true    => 'jenkins-www',
    default => 'jenkins',
  }

  nginx::resource::vhost { $vhost:
    ensure                => present,
    listen_port           => 80,
    ssl                   => false,
    access_log            => $access_log,
    error_log             => $error_log,
    proxy                 => 'http://jenkins',
    proxy_redirect        => 'default',
    proxy_connect_timeout => '150',
    proxy_set_header      => $proxy_set_header,
    # see comment above $raw_prepend declaration
    raw_prepend           => $enable_ssl ? {
      true     => $raw_prepend,
      default  => undef,
    },
  }
}
