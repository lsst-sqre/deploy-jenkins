vault setup
===

    secret/dm/square/jenkins/<env_name/<secret_name>

Example:

    secret/dm/square/jenkins/jhoblitt-curly/scipipe-publish

jenkins/casc secrets
---

```bash
vault kv put secret/dm/square/jenkins/jhoblitt-curly/slack slack_api_token=
vault kv put secret/dm/square/jenkins/jhoblitt-curly/ghslacker ghslacker_user= ghslacker_pass=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/github_oauth github_oauth_client_id= github_oauth_client_secret=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/github_api github_api_token=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/dockerhub dockerhub_user= dockerhub_pass=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/versiondb_ssh versiondb_ssh_private_key=@ssh_private_key versiondb_ssh_public_key=@ssh_public_key
```

k8s deployment secrets
---

```bash
vault kv put secret/dm/square/jenkins/jhoblitt-curly/grafana_oauth client_id= client_secret=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/prometheus_oauth client_id= client_secret=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/jenkins_agent user= pass=

vault kv put secret/dm/square/jenkins/jhoblitt-curly/tls crt=@ key=@


vault kv put secret/dm/square/jenkins/jhoblitt-curly/tls crt=@/home/jhoblitt/github/terragrunt-live-test/lsst-certs/lsst.codes/2018/lsst.codes_chain.pem key=@/home/jhoblitt/github/terragrunt-live-test/lsst-certs/lsst.codes/2018/lsst.codes.key

vault kv put secret/dm/square/jenkins/jhoblitt-curly/casc_vault token=
```

