module "snowflake" {
  source = "./modules/agent"

  name                = "snowflake"
  k8s_namespace       = "${kubernetes_namespace.jenkins.metadata.0.name}"
  agent_storage_class = "${local.k8s_storage_class}"
  agent_volume_size   = "500Gi"
  agent_user          = "${local.jenkins_agent_user}"
  agent_pass          = "${local.jenkins_agent_pass}"
  master_url          = "https://${local.master_alias}"
  agent_replicas      = "1"
  agent_labels        = ["snowflake"]
  agent_executors     = "1"
  agent_mode          = "exclusive"
  env_name            = "${var.env_name}"
}
