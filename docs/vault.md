vault setup
===

    secret/dm/square/jenkins/<env_name/<secret_name>

Example:

    secret/dm/square/jenkins/jhoblitt-curly/scipipe-publish



https://jhoblitt-larry-grafana-ci.lsst.codes/login/github

https://jhoblitt-larry-prometheus-ci.lsst.codes/oauth2


jenkins/casc secrets
---

### common

```bash
ENV_NAME=jhoblitt-curly
vault kv put secret/dm/square/jenkins/${ENV_NAME}/slack slack_api_token=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/ghslacker ghslacker_user= ghslacker_pass=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/github_oauth github_oauth_client_id= github_oauth_client_secret=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/github_api github_api_token=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/dockerhub dockerhub_user= dockerhub_pass=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/versiondb_ssh versiondb_ssh_private_key=@ssh_private_key versiondb_ssh_public_key=@ssh_public_key

```

### prod only

```bash
ENV_NAME=jhoblitt-curly
vault kv put secret/dm/square/jenkins/${ENV_NAME}/agent_ssh osx_ssh_private_key=@ssh_private_key osx_ssh_public_key=@ssh_public_key osx_ssh_user=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/cmirror cmirror_aws_access_key_id= cmirror_aws_secret_access_key=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/github_backup github_backup_aws_access_key_id= github_backup_aws_secret_access_key=
```

k8s deployment secrets
---

Required secrets:

* `grafana_oauth`
    Example github callback url https://${ENV_NAME}-grafana-ci.lsst.codes/login/github
* `prometheus_oauth`
    Example github callback url https://${ENV_NAME}-prometheus-ci.lsst.codes/oauth2
* `jenkins_agent`
* `tls`
* `scipipe-publish`
    Note that this secret is injected by a `terraform-scipipe-publish` deployment and is not expected to be configured manually.

```bash
ENV_NAME=jhoblitt-curly
vault kv put secret/dm/square/jenkins/${ENV_NAME}/grafana_oauth client_id= client_secret=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/prometheus_oauth client_id= client_secret=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/jenkins_agent user= pass=

vault kv put secret/dm/square/jenkins/${ENV_NAME}/tls crt=@ key=@
# vault kv put secret/dm/square/jenkins/${ENV_NAME}/tls crt=@/home/jhoblitt/github/terragrunt-live-test/lsst-certs/lsst.codes/2018/lsst.codes_chain.pem key=@/home/jhoblitt/github/terragrunt-live-test/lsst-certs/lsst.codes/2018/lsst.codes.key

vault kv put secret/dm/square/jenkins/${ENV_NAME}/casc_vault token=
```
