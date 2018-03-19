class jenkins_demo::profile::scl::devtoolset_6 {

  ensure_packages(['centos-release-scl'])

  package {[
    'devtoolset-6-gcc',
    'devtoolset-6-gcc-c++',
    'devtoolset-6-gcc-gfortran',
  ]:
    ensure  => present,
    require => Package['centos-release-scl'],
  }
}
