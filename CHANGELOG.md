changelog
=========

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
