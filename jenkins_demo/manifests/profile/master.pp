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

  jenkins::job { 'stack-os-matrix':
    config => template("${module_name}/jobs/stack-os-matrix/config.xml"),
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

  #
  # https://wiki.jenkins-ci.org/display/JENKINS/Jenkins+behind+an+NGinX+reverse+proxy

  selboolean { 'httpd_can_network_connect':
    value      => on,
    persistent => true,
  }

  nginx::resource::upstream { 'jenkins':
    ensure  => present,
    members => [
      'localhost:8080',
    ],
  }

  nginx::resource::vhost { 'jenkins':
    ensure                => present,
    server_name           => ['jenkins-master'],
    listen_port           => 80,
    ssl                   => false,
    access_log            => '/var/log/nginx/jenkins.access.log',
    error_log             => '/var/log/nginx/jenkins.error.log',
    proxy                 => 'http://jenkins',
    proxy_redirect        => 'default',
    proxy_set_header      => [
      'Host            $host',
      'X-Real-IP       $remote_addr',
      'X-Forwarded-For $proxy_add_x_forwarded_for',
    ],
    proxy_connect_timeout => '150',
  }
}
