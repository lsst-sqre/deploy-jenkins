class jenkins_demo::profile::squash::oauth {
  $defaults  = {
    http_address      => '127.0.0.1:4180',
    upstreams         => [ 'http://127.0.0.1:9090' ],
    # override w/ 32b string, see: https://golang.org/pkg/crypto/aes/#NewCipher
    cookie_secret     => '1234',
    pass_access_token => false,
    pass_host_header  => true,
    provider          => 'github',
    redirect_url      => "https://${::jenkins_demo::profile::squash::squash_fqdn}/oauth2/callback",
    email_domains     => [ '*' ],
  }

  class { '::oauth2_proxy':
    config => $defaults + $::jenkins_demo::profile::squash::oauth_config,
  }
}
