class jenkins_demo::profile::devtoolset_3 {
  # we are assuming the arch is always x86_64...
  $epel = $::operatingsystemmajrelease ? {
    '6'     => 'epel-6-x86_64',
    default => undef,
  }

  yumrepo { "rhscl-devtoolset-3-${epel}":
    ensure   => 'present',
    baseurl  => "https://www.softwarecollections.org/repos/rhscl/devtoolset-3/${epel}",
    descr    => "Devtoolset-3 - ${epel}",
    enabled  => '1',
    gpgcheck => '0',
  }

  #
  # some packages in devtoolset-3 require these SCLs; but apparently not the
  # current gcc packages.  They may need to be enabled if additional packages
  # from the devtoolset-3 SCL are used.
  #
  #yumrepo { "rhscl-maven30-${epel}":
  #  ensure   => 'present',
  #  baseurl  => "https://www.softwarecollections.org/repos/rhscl/maven30/${epel}",
  #  descr    => "Maven 3.0.5 - ${epel}",
  #  enabled  => '1',
  #  gpgcheck => '0',
  #}
  #yumrepo { "rhscl-rh-java-common-${epel}":
  #  ensure   => 'present',
  #  baseurl  => "https://www.softwarecollections.org/repos/rhscl/rh-java-common/${epel}",
  #  descr    => "Common Java Packages 1.1 - ${epel}",
  #  enabled  => '1',
  #  gpgcheck => '0',
  #}

  package { ['devtoolset-3-gcc', 'devtoolset-3-gcc-c++']:
    ensure  => present,
    require => Yumrepo["rhscl-devtoolset-3-${epel}"],
  }
}
