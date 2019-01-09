lookup('classes', {merge => unique}).include

$packages = lookup('packages', {
  merge         => 'unique',
  default_value => undef,
})

$files = lookup('files', {
  merge         => 'hash',
  default_value => undef,
})

$versionlocks = lookup('yum::versionlock', {
  merge         => 'hash',
  default_value => undef,
})

if ($packages) {
  package { $packages:
    ensure => present,
  }
}

if ($files) {
  create_resources(file, $files)
}

if ($versionlocks) {
  create_resources(yum::versionlock, $versionlocks)
  Class[yum] -> Class[java]
  Class[yum::plugin::versionlock] -> Class[java]
}
