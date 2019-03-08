Jenkins deployment update notes
===

Plumbing (the environment in which jenkins runs)
---

### Update to latest AWS Centos AMI

Note that as the production VM image is long living, updating the centos AMI
only effects new/re-provisioned test envs and prod agents. As the _running_
kernel version is enforced, `yum-autoupdate` is installing security updates,
and, theoretically, the versions of critical software packages are pinned,
updating the AMI is largely to ensure that incompatible changes are made to
the base distrib and to possibly save time updating components (Eg, the
kernel).

Select the latest version for the `us-east-1` region from the [AWS
Marketplace](https://aws.amazon.com/marketplace/pp/B00O7WM7QW?qid=1536178538453&sr=0-1&ref_=srh_res_product_title)

Update the `MASTER_AMI` string in `Vagrantfile`. Eg.

```ruby
def master_ami
  # us-east-1 centos 1805_01 (2018-06-12)
  ENV['MASTER_AMI'] || 'ami-9887c6e7'
end
```

### Update Java

*Note that the java packages are currrently pinned to versions from centos
7.5.1804, as more recent versions seem to break the jenkins master.*

In the past, strange problems were observed that appear to have been caused by
different java packages running on the jenkins master and the agents.  When
feasible, try to deploy updates to the entire environment at once.

An easy method of determining the most recent centos 7 `jdk 1.8.0` package:

```sh
$ docker run -ti centos:7
[root@6f033de8ab1f /]# yum info java-1.8.0-openjdk-devel.x86_64
Loaded plugins: fastestmirror, ovl
base                                                     | 3.6 kB     00:00
extras                                                   | 3.4 kB     00:00
updates                                                  | 3.4 kB     00:00
(1/4): base/7/x86_64/group_gz                              | 166 kB   00:00
(2/4): extras/7/x86_64/primary_db                          | 187 kB   00:00
(3/4): updates/7/x86_64/primary_db                         | 5.2 MB   00:01
(4/4): base/7/x86_64/primary_db                            | 5.9 MB   00:09
Determining fastest mirrors
 * base: mirrors.ocf.berkeley.edu
 * extras: mirrors.oit.uci.edu
 * updates: mirror.scalabledns.com
Available Packages
Name        : java-1.8.0-openjdk-devel
Arch        : x86_64
Epoch       : 1
Version     : 1.8.0.181
Release     : 3.b13.el7_5
Size        : 9.8 M
Repo        : updates/7/x86_64
Summary     : OpenJDK Development Environment
URL         : http://openjdk.java.net/
License     : ASL 1.1 and ASL 2.0 and BSD and BSD with advertising and GPL+ and
            : GPLv2 and GPLv2 with exceptions and IJG and LGPLv2+ and MIT and
            : MPLv2.0 and Public Domain and W3C and zlib
Description : The OpenJDK development tools.
```

Update the `java-1.8.0-openjdk*` package version in `hieradata/os/RedHat/7.yaml`.

```yaml
java::package: java-1.8.0-openjdk-devel-1.8.0.181-3.b13.el7_5
yum::versionlock:
  1:java-1.8.0-openjdk-1.8.0.181-3.b13.el7_5.x86_64: {}
  1:java-1.8.0-openjdk-headless-1.8.0.181-3.b13.el7_5.x86_64: {}
  1:java-1.8.0-openjdk-devel-1.8.0.181-3.b13.el7_5.x86_64: {}
```

### Update Centos 7 kernel

Over the course of the el7 series, numerous patches adding `docker` related
features have been back-ported from mainline the el7 kernel.  Frequently
updating the kernel has resolved various `docker` glitches and allowed new
features to be used such as `overlayfs`.

An easy method of determining the most recent centos 7 `kernel` package:

```sh
$ docker run -ti centos:7
[root@97967a250e5f /]# yum info kernel
Loaded plugins: fastestmirror, ovl
base                                                     | 3.6 kB     00:00
extras                                                   | 3.4 kB     00:00
updates                                                  | 3.4 kB     00:00
(1/4): extras/7/x86_64/primary_db                          | 187 kB   00:00
(2/4): base/7/x86_64/group_gz                              | 166 kB   00:00
(3/4): base/7/x86_64/primary_db                            | 5.9 MB   00:03
(4/4): updates/7/x86_64/primary_db                         | 5.2 MB   00:04
Determining fastest mirrors
 * base: mirrors.sonic.net
 * extras: yum.tamu.edu
 * updates: centos-distro.1gservers.com
Available Packages
Name        : kernel
Arch        : x86_64
Version     : 3.10.0
Release     : 862.11.6.el7
Size        : 46 M
Repo        : updates/7/x86_64
Summary     : The Linux kernel
URL         : http://www.kernel.org/
License     : GPLv2
Description : The kernel package contains the Linux kernel (vmlinuz), the core
            : of any Linux operating system.  The kernel handles the basic
            : functions of the operating system: memory allocation, process
            : allocation, device input and output, etc.

```

Update kernel version in `hieradata/os/RedHat/7.yaml`

```yaml
jenkins_demo::profile::kernel::version: '3.10.0-862.11.6.el7.x86_64'
```

### Update nginx

`yum` repo to check for updates:
http://nginx.org/packages/centos/7/x86_64/RPMS/

update nginx package version in `hieradata/common.eyaml`

```yaml
nginx::package_ensure: '1.14.0-1.el7_4.ngx'
```

### Update gems

In particular, to ensure that `librarian-puppet` is upgraded before attempting
to update puppet modules.

```sh
bundle update
git add Gemfile Gemfile.lock
git commit -m "update gems"
```

### Update puppet modules

Show outdated modules irrespective of version pinning:

```sh
bundle exec librarian-puppet outdated
```

```sh
bundle exec librarian-puppet update --verbose
bundle exec librarian-puppet install --verbose --destructive
git add Puppetfile Puppetfile.lock
git commit -m "update puppet modules"
```

This may fail due to conflicts -- this is normal.  Proceed to updating pinned
module versions.

Edit the `Puppetfile` to update pinned module versions by checking against the
output of `librarian-puppet outdated` and by inspecting module versions on the
(puppetforge](https://forge.puppet.com/).

If the librarian `update` failed, use:

```sh
bundle exec librarian-puppet install --verbose --destructive
```

after each pinned version is updated.  Be sure to also commit `Puppetfile.lock`
as part of each edit/install cycle.

Jenkins (core + plugins)
---

### Check core "release notes"

For the target core version:

* [LTS upgrade guide](https://jenkins.io/doc/upgrade-guide/)
* [LTS release notes](https://jenkins.io/changelog-stable/)

Note any minimum plugin version changes, configuration changes, warnings about
incompatible file formats, etc.

### Update jenkins core

Select the latest LTS rpm package but browsing the html index of the yum repo:
https://pkg.jenkins.io/redhat-stable/

Update the (rpm package) version in `hieradata/role/master.eyaml`

```yaml
jenkins::version: '2.121.3-1.1'
```

### Update `swarm` plugin + agents

The minimum swarm plugin version often changes with the core.  Pay special
attention to "remoting" changes in the LTS changelog/upgrade guide as this
often means a swarm upgrade is required.

The swarm plugin page https://plugins.jenkins.io/swarm usually lists the latest
version although there have occasionally been newer but not yet considered
stable versions published (which are not listed in the update center json
metadata).

* Update plugin version in `hieradata/role/master.eyaml`

```yaml
jenkins::master::version: '3.13'
```

* Update agent version in `hieradata/common.eyaml`

```yaml
jenkins::slave::version: '3.13'
```

### Bulk plugin update

* List installed / latest plugins

XXX This needs to be run locally as, at least, the nginx BO redirect is
breaking the /cli endpoint.

```sh
/bin/java -jar /usr/lib/jenkins/jenkins-cli.jar -s http://localhost:8080 -auth <user>:<github oauth token> list-plugins
```

Eg.,

```sh
[centos@jenkins-master ~]$ /bin/java -jar /usr/lib/jenkins/jenkins-cli.jar -s http://localhost:8080 -auth <user>:<github oauth token> list-plugins
credentials                        Credentials Plugin                                               2.1.18
configuration-as-code              Configuration as Code Plugin                                     1.1 (1.4)
configuration-as-code-support      Configuration as Code Support Plugin                             1.1 (1.4)
```

An easy way to get to the plugin information page to look at release notes is
via the plugin manager:

https://jhoblitt-moe-ci.lsst.codes/pluginManager/

_Note that for some plugins, the only information is in the wiki and the source
repo may need to be inspected for changesets._

* update plugin version in `hieradata/role/master.eyaml`

Note that new deps may need to be added.

### apply changes

If the kernel version has changed, the VM should reboot approximately 1 minute
after the puppet run completes.

```sh
vagrant rsync master
vagrant provision master
```

* IF jenkins master will start up, check logs for plugin errors:

https://jhoblitt-moe-ci.lsst.codes/log/all

Install missing plugins as needed to resolve error messages, file DM jira
issues for new error messages and report and/or google and/or link to existing
upstream issues in the jenkins jira https://issues.jenkins-ci.org/

Manual Acceptance Testing
---

If the test env __does not__ include osx build agents, disable the osx build
for the `stack-os-matrix` job so that it may complete successfully.

```sh
$ git checkout -b tickets/DM-15598-jenkins-update-test
Switched to a new branch 'tickets/DM-15598-jenkins-update-test'
$ git diff
diff --git a/etc/scipipe/build_matrix.yaml b/etc/scipipe/build_matrix.yaml
index eac65c0..97a229b 100644
--- a/etc/scipipe/build_matrix.yaml
+++ b/etc/scipipe/build_matrix.yaml
@@ -42,11 +42,6 @@ template:
 scipipe-lsstsw-matrix:
   - <<: *el6-py3
   - <<: *el7-py3
-  - <<: *osx-py3
-    #label: osx-10.11||osx-10.12
-    display_name: osx
-    #compiler: ^clang-802.0.42$ ^clang-800.0.42.1$
-    display_compiler: clang
 scipipe-lsstsw-ci_hsc:
   - <<: *el7-py3
 dax-lsstsw-matrix:
$ git add etc/scipipe/build_matrix.yaml
$ git commit -m "disable stack-os-matrix osx builds"
[tickets/DM-15598-jenkins-update-test 05eb82f] disable stack-os-matrix osx builds
 1 file changed, 5 deletions(-)
$ git push jhoblitt tickets/DM-15598-jenkins-update-test
Counting objects: 6, done.
Delta compression using up to 8 threads.
Compressing objects: 100% (5/5), done.
Writing objects: 100% (6/6), 1.05 KiB | 1.05 MiB/s, done.
Total 6 (delta 2), reused 1 (delta 0)
remote: Resolving deltas: 100% (2/2), completed with 2 local objects.
To github.com:jhoblitt/jenkins-dm-jobs.git
 * [new branch]      tickets/DM-15598-jenkins-update-test -> tickets/DM-15598-jenkins-update-test
```

See
https://github.com/lsst-sqre/deploy-jenkins/blob/master/quickstart.md#jenkins-job-development-workflow
for instructions on updating the fork/branch used for the "seed job".

* Trigger the `dm-jobs` seed job and check the console for deprecation messages

https://jhoblitt-moe-ci.lsst.codes/job/sqre/job/seeds/job/dm-jobs/

Check: https://github.com/jenkinsci/job-dsl-plugin/wiki/Migration

* Trigger `jenkins-node-cleanup` and inspect console output for errors

Note that the groovy script will likely need manual security approval after
`dm-jobs` has been reun.

https://jhoblitt-moe-ci.lsst.codes/scriptApproval/

https://jhoblitt-moe-ci.lsst.codes/job/sqre/job/infra/job/jenkins-node-cleanup/

* Trigger `stack-os-matrix` with a product of `cfitsio` and `SKIP_DEMO` checked.

https://jhoblitt-moe-ci.lsst.codes/job/stack-os-matrix/build?delay=0sec

This will inevitably fail due to the usage of groovy methods that haven't been
whitelisted by default in the groovy security sandbox for `pipeline` jobs.

Run the job and approve the method signature:

https://jhoblitt-moe-ci.lsst.codes/scriptApproval/

then replay the job. Iterate until the job finishes without triggered any more
security sandbox errors.

__This is a tedious process!__ At the time of this writing, this is the minimum
set of whitelisted signatures:

```java
method groovy.json.JsonBuilder toPrettyString
method groovy.json.JsonSlurperClassic parseText java.lang.String
method groovy.lang.GString getBytes
method hudson.model.Actionable getAction java.lang.Class
method hudson.model.Cause$UserIdCause getUserId
method hudson.model.CauseAction getShortDescription
method hudson.model.Run getCause java.lang.Class
method hudson.model.Run getDurationString
method hudson.plugins.git.GitSCM getBranches
method hudson.plugins.git.GitSCM getUserRemoteConfigs
method java.lang.StackTraceElement getMethodName
method java.lang.Throwable getStackTrace
method java.net.HttpURLConnection getResponseCode
method java.net.HttpURLConnection setRequestMethod java.lang.String
method java.net.URL openConnection
method java.net.URLConnection getInputStream
method java.net.URLConnection getOutputStream
method java.net.URLConnection setDoOutput boolean
method java.net.URLConnection setRequestProperty java.lang.String java.lang.String
method org.jenkinsci.plugins.workflow.support.steps.build.RunWrapper build
new groovy.json.JsonBuilder java.lang.Object
new groovy.json.JsonSlurperClassic
new java.lang.Throwable
staticMethod java.net.URLEncoder encode java.lang.String
staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods getText java.io.InputStream
staticMethod org.codehaus.groovy.runtime.DefaultGroovyMethods leftShift java.io.OutputStream java.lang.Object
staticMethod org.codehaus.groovy.runtime.EncodingGroovyMethods encodeBase64 byte[]
staticMethod org.codehaus.groovy.runtime.StackTraceUtils sanitize java.lang.Throwable

method java.net.URL openConnection
```

_Note that this generally isn't nessicary in the production envrionment as all
required groovy methods should already be whitelisted.  It is nessicary to
build up a new whitelist in each test env and its useful to run through the
process of re-creating the whitelist to get a sense of which methods are in
use._

* Verify that slack messages are being sent on the slack test channel.

Eg., `#dmjjm-stack-os-matrix`

* Check jenkins log (again) after https://jhoblitt-moe-ci.lsst.codes/log/all
