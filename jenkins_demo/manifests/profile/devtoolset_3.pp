class jenkins_demo::profile::devtoolset_3 {

  ensure_packages(['centos-release-scl'])

  package {[
    'devtoolset-3-gcc',
    'devtoolset-3-gcc-c++',
    'devtoolset-3-gcc-gfortran',
  ]:
    ensure  => present,
    require => Package['centos-release-scl'],
  }
}
