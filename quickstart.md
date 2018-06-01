jenkins dev env quick-start
===

Prerequisites
---

* vagrant >= 1.8.1
* `git` (needed to clone this repo)
* ruby >= 1.9.3
* ruby `bundler` gem
* ruby `hub` gem

Clone Source
---

    hub clone lsst-sqre/sandbox-jenkins-demo sandbox-jenkins-demo-<topic>
    cd sandbox-jenkins-demo-<topic>
    bundle install
    hub fork
    git branch -b tickets/<DM-XXXX>-<topic>

Configuration
---

    export AWS_ACCESS_KEY_ID=<...>
    export AWS_SECRET_ACCESS_KEY=<...>
    export AWS_DEFAULT_REGION=us-east-1

    export CENTOS6_AMI=ami-bef7d6d4
    export CENTOS7_AMI=ami-1bf4d571

    export MASTER_AMI=ami-fb135491

    export VAGRANT_DEFAULT_PROVIDER='aws'
    export VAGRANT_NO_PARALLEL='yes'

    export TF_VAR_aws_access_key=$AWS_ACCESS_KEY_ID
    export TF_VAR_aws_secret_key=$AWS_SECRET_ACCESS_KEY
    export TF_VAR_aws_default_region=$AWS_DEFAULT_REGION
    export TF_VAR_env_name=${USER}-jenkins
    export TF_VAR_aws_zone_id=Z3TH0HRSNU67AM
    export TF_VAR_domain_name=lsst.codes
    # must be at least 8 chars
    export TF_VAR_rds_password=<...>

It is recommended to save the env var configuration in a file named `creds.sh`
for convenience.

    cat > creds.sh <<END
    export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
    export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
    export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION

    export CENTOS6_AMI=$CENTOS6_AMI
    export CENTOS7_AMI=$CENTOS7_AMI

    export MASTER_AMI=$MASTER_AMI

    export VAGRANT_DEFAULT_PROVIDER='aws'
    export VAGRANT_NO_PARALLEL='yes'

    export TF_VAR_aws_access_key=$TF_VAR_aws_access_key
    export TF_VAR_aws_secret_key=$TF_VAR_aws_secret_key
    export TF_VAR_aws_default_region=$TF_VAR_aws_default_region
    export TF_VAR_env_name=$TF_VAR_env_name
    export TF_VAR_aws_zone_id=$TF_VAR_aws_zone_id
    export TF_VAR_domain_name=$TF_VAR_domain_name
    export TF_VAR_rds_password=$TF_VAR_rds_password
    END

Install `eyaml` key ring
---

NOTE: first download the lsst-sqre Dropbox folder to your home directory.

    mkdir .lsst-certs
    cd .lsst-certs
    git init
    git remote add origin ~/Dropbox/lsst-sqre/git/lsst-certs.git
    git config core.sparseCheckout true
    echo "eyaml-keys/" >> .git/info/sparse-checkout
    git pull --depth=1 origin master
    cd ..
    ln -s .lsst-certs/eyaml-keys keys

Generate ssh key pair
---

    (cd jenkins_demo/templates; make)

Create AWS VPC resources
---

    . creds.sh
    cd terraform
    # install terraform locally
    make
    # sanity check
    ./bin/terraform plan
    # create AWS VPC env
    ./bin/terraform apply
    cd ..

NOTE 1: For OSX the first `make` command may not work, then remove the -nc
 command line argument from the `wget` command in the `Makefile`.

NOTE 2: The state of your infrastructure is saved locally.
**This state is required to modify and destroy your
infrastructure, so keep it safe**. To inspect the complete state
use the `terraform show` command.

Configure github oauth2
---

    (
        cd ./terraform;
        ./bin/terraform show | grep JENKINS_FQDN | sed -e 's/.*\=\s\(.*\)/https:\/\/\1\/securityRealm\/finishLogin/'
    )

Example output.:

    https://jhoblitt-jenkins-ci.lsst.codes/securityRealm/finishLogin

### Register a new application(s)

A "personal" application may be registered via:

<https://github.com/settings/applications/new>

**Note that a production application should be attached to a github org.**

An application name and homepage URL are required but the values are not
significant. The callback URL must __exactly__ match the constructed URL.

### Edit oauth2 configuration

#### jenkins

Insert the `Client ID` and `Client Secret` strings under the
`jenkinsx::security_realm` key as the 3rd and 4th "arguments".

    bundle exec rake edit[hieradata/role/master.eyaml]

    jenkinsx::security_realm:
      org.jenkinsci.plugins.GithubSecurityRealm:
        arguments:
          - https://github.com
          - https://api.github.com
          - DEC(5)::PKCS7[XXXXXXXXXXXXXXXXXXXX]!
          - DEC(7)::PKCS7[XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX]!
          - read:org

Fork `jenkins-dm-jobs`
---

It is recommend the `jenkins-dm-jobs` clone *not* be nested under the
`sandbox-jenkins-demo`.

    cd
    hub clone lsst-sqre/jenkins-dm-jobs jenkins-dm-jobs-<topic>
    cd jenkins-dm-jobs-<topic>
    hub fork
    git checkout -b tickets/<DM-XXXX>-<topic>-dev
    git push $USER tickets/<DM-XXXX>-<topic>-dev

return to the `sandbox-jenkins-demo` clone

    cd
    cd sandbox-jenkins-demo-<topic>

Edit the jenkins "seed" job that pulls from `jenkins-dm-jobs` to point at the
development fork/branch.

    vi jenkins_demo/templates/jobs/seeds/jobs/dm-jobs/config.xml

      <scm class="hudson.plugins.git.GitSCM" plugin="git@2.5.2">
        <configVersion>2</configVersion>
        <userRemoteConfigs>
          <hudson.plugins.git.UserRemoteConfig>
            <url>https://github.com/lsst-sqre/jenkins-dm-jobs</url>
          </hudson.plugins.git.UserRemoteConfig>
        </userRemoteConfigs>
        <branches>
          <hudson.plugins.git.BranchSpec>
            <name>*/master</name>
          </hudson.plugins.git.BranchSpec>
        </branches>
        <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
        <submoduleCfg class="list"/>
        <extensions/>
      </scm>

Example:

    diff --git a/jenkins_demo/templates/jobs/seeds/jobs/dm-jobs/config.xml b/jenkins_demo/templates/jobs/seeds/jobs/dm-jobs/config.xml
    index 11eb8ed..a951c2e 100644
    --- a/jenkins_demo/templates/jobs/seeds/jobs/dm-jobs/config.xml
    +++ b/jenkins_demo/templates/jobs/seeds/jobs/dm-jobs/config.xml
    @@ -17,12 +17,12 @@
         <configVersion>2</configVersion>
         <userRemoteConfigs>
           <hudson.plugins.git.UserRemoteConfig>
    -        <url>https://github.com/lsst-sqre/jenkins-dm-jobs</url>
    +        <url>https://github.com/jhoblitt/jenkins-dm-jobs</url>
           </hudson.plugins.git.UserRemoteConfig>
         </userRemoteConfigs>
         <branches>
           <hudson.plugins.git.BranchSpec>
    -        <name>*/master</name>
    +          <name>*/tickets/DM-8549-gh-snapshot</name>
           </hudson.plugins.git.BranchSpec>
         </branches>
         <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
    @@ -64,4 +64,4 @@
         </jenkins.plugins.hipchat.HipChatNotifier>
       </publishers>
       <buildWrappers/>
    -</project>
    \ No newline at end of file
    +</project>

Decrypt eyaml values and install puppet modules
---

    bundle exec rake

NOTE: This command must be re-run after editing under the `jenkins_demo`
directory.

NOTE: make sure you are running this on a clean repository otherwise the
'bundle exec rake' will not update the corresponding yaml files.

Start jenkins master + agent VM instance(s)
---

    . creds.sh
    vagrant up master
    vagrant up el7-1

Applying changes to a running instance
---

    . creds.sh
    bundle exec librarian-puppet update
    vagrant rsync master
    vagrant provision master

Jenkins job development workflow
---

* Make changes to `jenkins-dm-jobs` and push the dev branch.

XXX jenkins can automatically trigger the seed job for `jenkins-dm-jobs` upon
push but it needs to be configured with credentials that can setup web-hooks in
the developers fork.  This procedure should be documented at some point...

* Trigger a build of the `seed` job. Eg.

<https://ci.lsst.codes/job/seeds/job/dm-jobs/build?delay=0sec>

* iterate as necessary

* prepare a clean "PR" branch

Job development will often require dev/test commits that should not be merged
to master.  So as not to "break" the dev branch, it is recommended that a
separate "sanitized" branch be used for PRs back to master.

Eg.

    git checkout -b tickets/<DM-XXXX>-<topic> # no -dev postfix
    git rebase -i origin/master # remove any (TESTING) commits
    git push $USER tickets/<DM-XXXX>-<topic>
    hub pull-request

### building dev branches

Often the source repo(s)/branch(es) in a job under development will need to be
pointed at a forks in order to decouple the production environment from
dev/test instances. A common example of this is when changes to
`lsst-sqre/buildbot-scripts` are required.  Such changes obviously should not
be merged into the production branch.  The recommend procedure to to prefix the
commit message of dev/test only changesets with `(TESTING)`.  This is to make
it obvious which commits should not be included in a PR back to the master
branch.

### timer triggered jobs

XXX There are a number of jobs present in `jenkins-dm-jobs` which are
periodically triggered by timers. This includes periodic builds of the DM
pipeline code, weekly tagging and backups.  In particular, it is not desirable
for weekly tags or backups to be run concurrently between the production and
any development jenkins instances.  These jobs either need to be split out into
a separate repo or a development template which disables them needs to be
provided.

At present, the simplest solution is to simply remove all timer triggered jobs
from the dev branch. Eg.

    git rm validate_drp.groovy jenkins_ebs_snapshot.groovy weekly_release.groovy run_rebuild.groovy stack_wrappers.groovy sqre_github_snapshot.groovy
    git commit -m "(TESTING) remove timer triggered jobs"

Debug
---

Use the following command to inspect the logs in your instance:

    sudo journalctl -xe -f

Cleanup
---

    . creds.sh
    # VM must be destroyed before some AWS resources may be deallocated
    vagrant destroy -f
    cd terraform
    ./bin/terraform destroy --force
    cd ..
    rm -rf .lsst-certs
