lookup('classes', {merge => unique}).include

$packages = lookup('packages', {
  merge         => unique,
  default_value => undef,
})

if ($packages) {
  package { $packages:
    ensure => present,
  }
}
