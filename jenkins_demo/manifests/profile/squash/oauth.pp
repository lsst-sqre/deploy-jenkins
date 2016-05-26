class jenkins_demo::profile::squash::oauth {
  $squash_defaults  = {
    http_address      => '127.0.0.1:4180',
    upstreams         => [ 'http://127.0.0.1:9090' ],
    # override w/ 32b string, see: https://golang.org/pkg/crypto/aes/#NewCipher
    cookie_name       => $::demo_name,
    cookie_domain     => $::domain_name,
    cookie_secure     => true,
    cookie_secret     => '1234',
    pass_access_token => false,
    pass_host_header  => true,
    provider          => 'github',
    redirect_url      => "https://${::jenkins_demo::profile::squash::squash_fqdn}/oauth2/callback",
    email_domains     => [ '*' ],
  }

  $end = $::jenkins_demo::profile::squash::bokeh_instances - 1

  $bokeh_members = range(0, $end).reduce([]) |Array $memo, Integer $n| {
    $port = $::jenkins_demo::profile::squash::bokeh_base_port + $n
    $memo + "http://127.0.0.1:${port}"
  }

  $bokeh_defaults = $squash_defaults + {
    http_address => '127.0.0.1:4181',
    upstreams    => $bokeh_members,
    redirect_url => "https://${::jenkins_demo::profile::squash::bokeh_fqdn}/oauth2/callback",
  }

  include ::oauth2_proxy

  # XXX note that we are using $::jenkins_demo::profile::squash::oauth_config
  # for both the `squash` and `bokeh` proxy instances.  This works well because
  # the provder config, cookie name, cookie secret, and cookie domain must be
  # syncronized between instances.  However, this will likely cause a strange
  # failure mode if `redirect_url` is set.
  ::oauth2_proxy::instance { 'squash':
    config => $squash_defaults + $::jenkins_demo::profile::squash::oauth_config,
  }

  ::oauth2_proxy::instance { 'bokeh':
    config => $bokeh_defaults + $::jenkins_demo::profile::squash::oauth_config,
  }
}
