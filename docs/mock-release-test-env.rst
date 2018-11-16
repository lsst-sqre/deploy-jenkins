deploy-publish-release
----------------------

See https://github.com/lsst-sqre/deploy-publish-release for update-to-date
deployment instructions.

Example:

.. code-block:: bash

   hub clone lsst-sqre/deploy-publish-release deploy-publish-release-curly
   cd deploy-publish-release-curly
   bundle install
   bundle exec rake creds
   # edit TF_VAR_env_name=<env name> in creds.sh
   source creds.sh
   cd tf
   make tf-init-s3
   make tls
   ./bin/terraform plan
   ./bin/terraform apply

jenkins-dm-jobs
---------------

Fork / create a branch of ``lsst-sqre/jenkins-dm-jobs`` for the test env, Eg.,
``provingground/curly``

deploy-jenkins
--------------

See the ``quickstart.md`` deployment docs.  Configure jenkins to use the above
fork/branch of ``jenkins-dm-jobs``.


New github "test" org
---------------------

- create a new ``sqre-codekit`` github user (the production user is
  ``sqreadmin``) via:
  https://github.com/join?source=header-home

  - note that a unique email address per account **is required**.

  - add the credentials for this user to the sqre password management
    application.

  - verify the account email address by following the emailed link.

- create a new "test" github organization (Eg., ``provingground-curly``) via:
  https://github.com/organizations/new

  - The org should be flagged as a "business org" owned by something like
    ``LSST/AURA Inc.``

- Skip the invite dialog at org creation time as is does not allow users to be
  invited with a specific role.  Instead, use the https://github.com/orgs/<org
  name>/people page.  Add the ``sqre-codekit`` user as a **owner** of the new
  org (only owners are able to manage team membership).  This user should not
  be added to any other LSST associated orgs so as to provide
  privilege separation for the test env.

- add the ``sqreadmin`` user as an **owner**.  This account should be an owner
  of all ``SQRE`` associated github orgs.  Note that the ``sqreadmin`` account
  will need to login to the github website in order to accept the invite.

- and your personal user account to the org as an **owner**.

- obtain an oauth token for the ``sqre-codekit`` user and save it for later
  use.  Note that **it is not used with ``github-fork-org``**.

.. code-block:: bash

   $ docker run -ti lsstsqre/codekit:7.4.0 bash
   codekit@4f37b25ce6ca:/$
   export TESTORG_USER=<github user>
   $ github-auth \
     --user "$TESTORG_USER" \
     --delete-role \
     --token-path ./github-token.txt

         Type in your password to get an auth token from github
         It will be stored in ./sqreadmincurly-github-token.txt
         and used in subsequent occasions.

   Password for sqreadmincurly:
   Token written to ./sqreadmincurly-github-token.txt
   $ cat ./github-token.txt
   ...

- fork repos from ``lsst`` org into the "testing" org, named
  ``provingground-curly`` in this example.

  **Note that the credentials for the ``sqreadmin`` user must be used for this
  step as copying teams requires admin permissions in both the source and
  destination orgs.**

FIXME: --copy-teams seems to be broken when used with --dry-run ???
FIXME: bogus repo already exists warnings (something has changed with github api???) WARNING:codekit:fork of provingground-curly/validation_data_decam already exist

.. code-block:: bash

   $ docker run -ti lsstsqre/codekit:7.4.0 bash
   codekit@a65feca5b0b1:/$
   codekit@a65feca5b0b1:/$ export SQREADMIN_TOKEN=<oauth token>
   codekit@a65feca5b0b1:/$ export TEST_ORG=provingground-curly
   codekit@a65feca5b0b1:/$ github-fork-org \
       --src-org 'lsst' \
       --dst-org "$TEST_ORG" \
       --token "$SQREADMIN_TOKEN" \
       --team 'DM Auxilliaries' \
       --team 'DM Externals' \
       --team 'Data Management' \
       --team 'DM CI Test' \
       --copy-teams \
       --debug


To fork additional repos to an existing "test" org
--------------------------------------------------

Existing teams should be wiped out:

.. code-block:: bash

   github-decimate-org \
       --debug \
       --org 'provingground-curly' \
       --token "$SQREADMIN_TOKEN" \
       --delete-teams


then ``github-fork-org`` should be run as above.


New docker hub "test" org
-------------------------

**Note that docker hub DOES NOT support personal access tokens and a user/pass
must be used directly to access the API.**

- create new user

   A unique email address is required per user.

- create new org

  **Note that docker hub orgs may not contain dashes.**

  Example:

  provingground-larry
  proving ground for larry
  LSST/AURA Inc.
  Distributed
  <leave email address for gravatar blank>
  https://lsst.org

  - add to owners team
    1. new user
    2. personal account
    3. sqreadmin


Setup ``versiondb``
-------------------

Create a new ssh key pair

.. code-block:: bash

   ssh-keygen -t rsa -f id_rsa -N '' -C 'jhoblitt-curly@versiondb'


github deploy key
^^^^^^^^^^^^^^^^^

Install as "deploy keys" in ``versiondb`` repo via:
https://github.com/provingground-curly/versiondb/settings/keys/new

Name the key something like ``jenkins jhoblitt-curly``.

Note that the deploy key must have writes enabled (Ie., ``Allow write access`` is checked).

XXX Could this be done via the github api instead?

install in jenkins
^^^^^^^^^^^^^^^^^^

The private ssh key for deploying to the ``versiondb`` repo needs to be installed into jenkins as a credential named ``github-jenkins-versiondb``

.. code-block:: bash

   bundle exec rake edit[hieradata/deploy/jhoblitt-curly.eyaml]

.. code-block:: yaml

   jenkinsx::versiondb:
     ssh_private_key: &jenkinsx_versiondb_ssh_private_key |
       DEC::PKCS7[-----BEGIN RSA PRIVATE KEY-----
       ...
       -----END RSA PRIVATE KEY-----]!
     ssh_public_key: |
       ...
   jenkinsx::casc
     credentials:
       system:
         domainCredentials:
           - credentials:
               - string:
                   id: github-api-token-sqreadmin
                   scope: GLOBAL
                   description: github API personal access token (sqreadmincurly)
                   secret: DEC::PKCS7[...]!
               - basicSSHUserPrivateKey:
                   id: github-jenkins-versiondb
                   scope: GLOBAL
                   description: github provingground-curly/versiondb deploy key
                   username: git
                   privateKeySource:
                      directEntry:
                         privateKey: *jenkinsx_versiondb_ssh_private_key
               - usernamePassword:
                   id: dockerhub-sqreadmin
                   scope: GLOBAL
                   description: dockerhub (sqreadmincurly)
                   username: DEC::PKCS7[...]!
                   password: DEC::PKCS7[...]!

XXX The github-api-token-sqreadmin credential should probably be renamed to
make its usage better self documenting.

Configure jenkins jobs
----------------------

.. code-block:: bash

   $ git diff
   diff --git a/etc/scipipe/build_matrix.yaml b/etc/scipipe/build_matrix.yaml
   index 8005d6c..5756455 100644
   --- a/etc/scipipe/build_matrix.yaml
   +++ b/etc/scipipe/build_matrix.yaml
   @@ -98,20 +98,20 @@ release:
      s3_wait_time: 15
      step:
        build_jupyterlabdemo:
   -      image_name: lsstsqre/jld-lab
   +      image_name: lsstsqre/jhoblitt-curly-jld-lab
        validate_drp:
   -      no_push: false
   +      no_push: true
        documenteer:
   -      publish: true
   +      publish: false
    #
    # low-level build parameters
    #
    repos:
   -  github_repo: lsst/repos
   +  github_repo: provingground-curly/repos
      git_ref: master
    versiondb:
   -  github_repo: lsst/versiondb
   -release_tag_org: lsst
   +  github_repo: provingground-curly/versiondb
   +release_tag_org: provingground-curly
    lsstsw:
      github_repo: lsst/lsstsw
      git_ref: master
   @@ -132,7 +132,7 @@ scipipe_release:
        git_ref: master
        dir: ''
      docker_registry:
   -    repo: lsstsqre/centos
   +    repo: lsstsqre/jhoblitt-curly-centos
    newinstall:
      dockerfile:
        github_repo: lsst-sqre/docker-newinstall

   git commit -p -m"(TESTING) provingground-curly fork"
   git push jhoblitt provingground/curly

- disable OSX tarball builds

.. code-block:: bash

   $ git diff
   diff --git a/etc/scipipe/build_matrix.yaml b/etc/scipipe/build_matrix.yaml
   index 5756455..3564e5c 100644
   --- a/etc/scipipe/build_matrix.yaml
   +++ b/etc/scipipe/build_matrix.yaml
   @@ -84,12 +84,12 @@ tarball:
        # need newinstall.sh support for devtoolset-7
        # - <<: *tarball_defaults
        #  <<: *el7-dts7-py3
   -    - <<: *tarball_defaults
   -      <<: *osx-py3
   -      platform: '10.9'
   -      osfamily: osx
   -      timelimit: 8
   -      allow_fail: true
   +    #- <<: *tarball_defaults
   +    #  <<: *osx-py3
   +    #  platform: '10.9'
   +    #  osfamily: osx
   +    #  timelimit: 8
   +    #  allow_fail: true
    #
    # X-release pattern pipelines
    #

   git commit -p -m"(TESTING) disable OSX tarball builds"
   git push jhoblitt provingground/curly

- don't require an agent with snowflake node label

If there is only one agent attached to the master it is safe to use it for both
the canoncial build and producing linux tarballs.

.. code-block:: bash

   $ git diff
   diff --git a/etc/scipipe/build_matrix.yaml b/etc/scipipe/build_matrix.yaml
   index 3564e5c..2c310e5 100644
   --- a/etc/scipipe/build_matrix.yaml
   +++ b/etc/scipipe/build_matrix.yaml
   @@ -59,7 +59,7 @@ canonical:
      products: &canonical_products lsst_distrib lsst_ci
      lsstsw_config:
        <<: *el7-py3
   -    label: jenkins-snowflake-1
   +    label: docker
        display_name: centos-7
      workspace: snowflake/release
    #

   git commit -p -m"(TESTING) disable snowflake label"
   git push jhoblitt provingground/curly

seed eups pkgroot
-----------------

Copy existing source ``eupspkg`` files into new eups pkgroot.

.. code-block:: bash

   aws s3 sync s3://eups.lsst.codes/stack/src s3://jhoblitt-curly-eups.lsst.codes/stack/src

**It is highly recommend to run this operation on an EC2 instance for both performance and to avoid bandwidth charges.**

repos.yaml
----------

.. code-block:: bash

   hub clone provingground-curly/repos repos-curly
   cd repos-curly
   sed -i 's|github.com/lsst/|github.com/provingground-curly/|' etc/repos.yaml
   git diff
   git add etc/repos.yaml
   git commit -m "(TESTING) provingground-curly"
   git push origin master


docker images
-------------

* ``sqre/infra/build-layercake``

Note that a build of this job should automatically trigger
``.../build-newinstall``.

* ``sqre/infra/build-newinstall``

Needed to setup ``LSST_EUPS_PKGROOT_BASE_URL`` for the current env.

Note that a build of this job should automatically trigger
``../build-documenteer-base``.
