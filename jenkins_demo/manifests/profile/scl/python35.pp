class jenkins_demo::profile::scl::python35 {
  require ::jenkins_demo::profile::scl
  ensure_packages(['rh-python35'])
}
