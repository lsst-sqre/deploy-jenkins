class jenkins_demo::profile::scl::devtoolset_4 {

  ensure_packages(['centos-release-scl'])

  package {[
    'devtoolset-4-gcc',
    'devtoolset-4-gcc-c++',
    'devtoolset-4-gcc-gfortran',
  ]:
    ensure  => present,
    require => Package['centos-release-scl'],
  }
}
