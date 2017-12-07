class jenkins_demo::profile::master(
  $seed_url = 'https://github.com/lsst-sqre/jenkins-dm-jobs',
  $seed_ref = '*/master',
) {
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
  jenkins_exec{ 'job-dsl security':
    script => @(END)
      import jenkins.model.*

      def j = Jenkins.getInstance()
      def jobDsl = j.getDescriptor("javaposse.jobdsl.plugin.GlobalJobDslSecurityConfiguration")
      jobDsl.setUseScriptSecurity(false)
    END
  }

  $admin_key_path  = '/usr/lib/jenkins/admin_private_key'
  $j = lookup('jenkinsx', Hash[String, String])

  file { $admin_key_path:
    ensure  => file,
    owner   => 'jenkins',
    group   => 'jenkins',
    mode    => '0664',
    content => $j['ssh_private_key'],
  }

  class { 'jenkins::cli::config':
    ssh_private_key => $admin_key_path,
    cli_remoting_free   => false,
    cli_legacy_remoting => true,
  }

  $user_hash = lookup('jenkinsx::user',
                      Hash[String,
                        Hash[String,
                          Variant[String, Array[String]]]])
  create_resources('jenkins_user', $user_hash)

  $strategy = lookup('jenkinsx::authorization_strategy',
                     Hash[String,
                       Hash[String,
                         Array[Variant[String, Boolean]]]])
  create_resources('jenkins_authorization_strategy', $strategy)

  $realm = lookup('jenkinsx::security_realm',
                  Hash[String,
                    Hash[String,
                      Array[String]]])
  create_resources('jenkins_security_realm', $realm)

  $creds = lookup('jenkinsx::credentials',
                  Hash[String,
                    Hash[String,
                      Variant[String, Undef]]])
  create_resources('jenkins_credentials', $creds)

  # run a jnlp slave to execute jobs that need to be bound to the
  # jenkins-master node (E.g., backups).  This provides some priviledge
  # separation between the master process and the builds as they will be
  # executed under the jenkins-slave user.  jenkins user.
  class { 'jenkins::slave':
    masterurl  => 'http://jenkins-master:8080',
    slave_name => $::hostname,
    labels     => $::hostname,
    executors  => 8,
    slave_mode => 'exclusive',
  }

  class { 'python' :
    version    => 'system',
    pip        => 'present',
    dev        => 'present',
    virtualenv => 'present',
  }

  jenkins_job { 'sqre':
    config => template("${module_name}/jobs/sqre/config.xml"),
  }

  jenkins_job { 'sqre/seeds':
    config => template("${module_name}/jobs/sqre/jobs/seeds/config.xml"),
  }

  jenkins_job { 'sqre/seeds/dm-jobs':
    config => epp("${module_name}/jobs/sqre/jobs/seeds/jobs/dm-jobs/config.xml.epp", {
      seed_url => $seed_url,
      seed_ref => $seed_ref,
    }),
  }

  # puppet-jenkins does not presently support the management of nodes
  # XXX this is a dirty hack
  $nodes = lookup('jenkinsx::nodes', Hash[String, Hash], 'first', undef)
  if $nodes {
    create_resources('jenkins_demo::profile::jenkins::node', $nodes)
  }

  # XXX this is [also] a dirty hack
  $jenkins_url = lookup('jenkins_fqdn', String, 'first', $::jenkins_fqdn)
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

  # cleanup jenkins plugin configuration
  file { '/var/lib/jenkins/jenkins.plugins.hipchat.HipChatNotifier.xml':
    ensure => absent,
  }

  $slack = lookup('jenkins::plugins::slack',
                  Hash[String, String], 'first', undef)
  if $slack {
    $slack_xml = 'jenkins.plugins.slack.SlackNotifier.xml'
    jenkins::plugin { 'slack':
      manage_config   => true,
      version         => '2.3',
      config_filename => $slack_xml,
      config_content  => template("${module_name}/plugins/${slack_xml}"),
    }
  }

  $ansicolor_xml = 'hudson.plugins.ansicolor.AnsiColorBuildWrapper.xml'
  jenkins::plugin { 'ansicolor':
    manage_config   => true,
    version         => '0.5.2',
    config_filename => $ansicolor_xml,
    config_content  => template("${module_name}/plugins/${ansicolor_xml}"),
  }

  $github_xml = 'github-plugin-configuration.xml'
  jenkins::plugin { 'github':
    manage_config   => true,
    version         => '1.28.1',
    config_filename => $github_xml,
    config_content  => template("${module_name}/plugins/${github_xml}"),
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

  if $ssl_cert and $ssl_key {
    $enable_ssl = true
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
    "if ( \$http_referer ~ ^(?!https://${jenkins_fqdn}) ) {",
    "  rewrite ^/$ https://${jenkins_fqdn}/blue/organizations/jenkins last;",
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

  # lint:ignore:selector_inside_resource
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
  # lint:endignore
}
