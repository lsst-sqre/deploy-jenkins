module "snowflake" {
  source = "./modules/agent"

  name                = "snowflake"
  k8s_namespace       = "${kubernetes_namespace.jenkins.metadata.0.name}"
  agent_storage_class = "${local.k8s_storage_class}"
  agent_volume_size   = "500Gi"
  agent_user          = "${var.jenkins_agent_user}"
  agent_pass          = "${var.jenkins_agent_pass}"
  master_url          = "https://${local.master_alias}"
  agent_replicas      = "1"
  agent_labels        = ["docker", "snowflake"]
  agent_executors     = "1"
  agent_mode          = "exclusive"
}
