class jenkins_demo::profile::master {
  include ::wget # needed by jenkins
  include ::nginx

  Class['::wget'] -> Class['::jenkins']
  # lint:ignore:arrow_alignment
  class { 'jenkins':
    configure_firewall => false,
    cli                => true,
    #executors          => 0,
    config_hash        => {
      'JENKINS_LISTEN_ADDRESS' => { 'value' => '' },
      'JENKINS_HTTPS_PORT'     => { 'value' => '' },
      'JENKINS_AJP_PORT'       => { 'value' => '-1' },
    },
  }
  # lint:endignore
  include ::jenkins::master # <- I am a swarm master

  jenkins_num_executors{ '0': ensure => present }
  jenkins_slaveagent_port{ '55555': ensure => present }

  $admin_key_path  = '/usr/lib/jenkins/admin_private_key'
  $j = hiera('jenkinsx', undef)

  file { $admin_key_path:
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0664',
    content => $j['ssh_private_key'],
  }

  class { 'jenkins::cli::config':
    ssh_private_key => $admin_key_path,
  }

  $user_hash = hiera('jenkinsx::user', undef)
  create_resources('jenkins_user', $user_hash)

  $strategy = hiera('jenkinsx::authorization_strategy', undef)
  create_resources('jenkins_authorization_strategy', $strategy)

  $realm = hiera('jenkinsx::security_realm', undef)
  create_resources('jenkins_security_realm', $realm)

  $creds = hiera('jenkinsx::credentials', undef)
  create_resources('jenkins_credentials', $creds)

  # run a jnlp slave to execute jobs that need to be bound to the
  # jenkins-master node (E.g., backups).  This provides some priviledge
  # separation between the master process and the builds as they will be
  # executed under the jenkins-slave user.  jenkins user.
  class { 'jenkins::slave':
    masterurl    => 'http://jenkins-master:8080',
    slave_name   => $::hostname,
    labels       => $::hostname,
    executors    => 8,
    slave_mode   => 'exclusive',
  }

  jenkins_job { 'stack-os-matrix':
    config => template("${module_name}/jobs/stack-os-matrix/config.xml"),
  }

  class { 'python' :
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
  }

  jenkins_job { 'jenkins-ebs-snapshot':
    config => template("${module_name}/jobs/jenkins-ebs-snapshot/config.xml"),
  }

  jenkins_job { 'run-rebuild':
    config => template("${module_name}/jobs/run-rebuild/config.xml"),
  }

  jenkins_job { 'run-publish':
    config => template("${module_name}/jobs/run-publish/config.xml"),
  }

  jenkins_job { 'ci_hsc':
    config => template("${module_name}/jobs/ci_hsc/config.xml"),
  }

  jenkins_job { 'validate_drp':
    config => template("${module_name}/jobs/validate_drp/config.xml"),
  }

  jenkins_job { 'seeds':
    config => template("${module_name}/jobs/seeds/config.xml"),
  }

  jenkins_job { 'seeds/dm-jobs':
    config => template("${module_name}/jobs/seeds/jobs/dm-jobs/config.xml"),
  }

  $lsst_dev = hiera('jenkinsx::nodes::lsst_dev', false)
  if $lsst_dev {
    # puppet-jenkins does not presently support the management of nodes
    # XXX this is a dirty hack
    file { [
      '/var/lib/jenkins/nodes',
      '/var/lib/jenkins/nodes/lsst-dev',
    ]:
      ensure => directory,
      owner  => 'jenkins',
      group  => 'jenkins',
      mode   => '0755',
    }

    file { '/var/lib/jenkins/nodes/lsst-dev/config.xml':
      ensure  => file,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      # the sshslave plugin version shows up in the dump making it non-idempotent
      replace => false,
      content => template("${module_name}/nodes/lsst-dev/config.xml"),
      notify  => Class['jenkins::service'],
    }
  }


  # XXX this is [also] a dirty hack
  $jenkins_url = hiera('jenkins_fqdn', $::jenkins_fqdn)
  file { '/var/lib/jenkins/jenkins.model.JenkinsLocationConfiguration.xml':
      ensure  => file,
      owner   => 'jenkins',
      group   => 'jenkins',
      mode    => '0644',
      notify  => Class['jenkins::service'],
      content => inline_template(
"<?xml version='1.0' encoding='UTF-8'?>
<jenkins.model.JenkinsLocationConfiguration>
  <adminAddress>address not configured yet &lt;nobody@nowhere&gt;</adminAddress>
  <jenkinsUrl>https://<%= @jenkins_url %>/</jenkinsUrl>
</jenkins.model.JenkinsLocationConfiguration>
"),
  }


  $hipchat = hiera('jenkins::plugins::hipchat', undef)

  if $hipchat {
    $hipchat_xml = 'jenkins.plugins.hipchat.HipChatNotifier.xml'
    jenkins::plugin { 'hipchat':
      manage_config   => true,
      version         => '1.0.0',
      config_filename => $hipchat_xml,
      config_content  => template("${module_name}/plugins/${hipchat_xml}"),
    }
  }

  $ansicolor_xml = 'hudson.plugins.ansicolor.AnsiColorBuildWrapper.xml'
  jenkins::plugin { 'ansicolor':
    manage_config   => true,
    version         => '0.4.2',
    config_filename => $ansicolor_xml,
    config_content  => template("${module_name}/plugins/${ansicolor_xml}"),
  }

  $collapsing_xml = 'org.jvnet.hudson.plugins.collapsingconsolesections.CollapsingSectionNote.xml'
  jenkins::plugin { 'collapsing-console-sections':
    manage_config   => true,
    version         => '1.4.1',
    config_filename => $collapsing_xml,
    config_content  => template("${module_name}/plugins/${collapsing_xml}"),
  }

  $github_xml = 'github-plugin-configuration.xml'
  jenkins::plugin { 'github':
    manage_config   => true,
    version         => '1.17.1',
    config_filename => $github_xml,
    config_content  => template("${module_name}/plugins/${github_xml}"),
  }

  $ghprb_xml = 'org.jenkinsci.plugins.ghprb.GhprbTrigger.xml'
  jenkins::plugin { 'ghprb':
    manage_config   => true,
    version         => '1.30.6',
    config_filename => $ghprb_xml,
    config_content  => template("${module_name}/plugins/${ghprb_xml}"),
  }

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
  $jenkins_fqdn        = hiera('jenkins_fqdn', $::jenkins_fqdn)

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
    "if ( \$host != \'${jenkins_fqdn}\' ) {",
    "  return 301 https://${jenkins_fqdn}\$request_uri;",
    '}',
  ]

  if $enable_ssl {
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
    rewrite_to_https      => $enable_ssl ? {
      true    => true,
      default => false,
    },
    # see comment above $raw_prepend declaration
    raw_prepend           => $enable_ssl ? {
      true    => $raw_prepend,
      default => undef,
    },
  }
}
