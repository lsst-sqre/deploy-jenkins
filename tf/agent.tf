module "agent" {
  source = "./modules/agent"

  name                = "agent"
  k8s_namespace       = "${kubernetes_namespace.jenkins.metadata.0.name}"
  agent_storage_class = "${kubernetes_storage_class.gp2.metadata.0.name}"
  agent_volume_size   = "${var.jenkins_agent_volume_size}"
  agent_user          = "${var.jenkins_agent_user}"
  agent_pass          = "${var.jenkins_agent_pass}"
  master_url          = "https://${local.master_alias}"
  agent_replicas      = "${var.jenkins_agent_replicas}"
  agent_labels        = ["docker"]
}
