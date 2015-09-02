changelog
=========

0.4.0
-----

* use devtoolset-3 for CI builds on EL6
* do not explicitly set "master" as the default branch in the `stack-os-matrix`
  family of jobs

0.3.1
-----

* rename hipchat room "Bot: Jenkins Demo -> Bot:Jenkins"


0.3.0
-----

* split qserv_distrib & dax_webserv out of stack-os-matrix
* fix compatibility with jfryman/nginx v0.2.7


0.2.4
-----

* add psmisc package to build slaves


0.2.3
-----

* add missing 0.2.[12] changelog


0.2.2
-----

* remove accidentally hard coded test urls


0.2.1
-----

* remove accidentally hard coded test urls


0.2.0
-----

Notable changes:

* add ganglia metric collection (https://<jenkins-master>/ganglia/)
* fix postbuild script intended to terminate zombie lsstsw/rebuild processes
* add hiera-eyaml support for mixed plaintext/encypted values in `common.eyaml`
* add TLS support and a public CA signed keypair for *.lsst.codes
* add jenkins-ec2-snapshot job to make EBS snapshots (backups) of jenkins-master
* add jenkins purge-build-queue-plugin plugin; removes all pending builds
* the AWS_REGION env var has been renamed to AWS_DEFAULT_REGION
* http/s redirection to canonical site name
* assorted usability and doc improvements


0.1.0
-----

* first release
