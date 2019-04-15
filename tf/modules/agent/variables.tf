variable "name" {
  description = "name of statefulset that creates jenkins agents."
}

variable "k8s_namespace" {
  description = "k8s namespace to manage resources within."
  default     = "jenkins"
}

variable "agent_volume_size" {
  description = "Persistent volume for agent -- must include a unit postfix. Eg., Gi."
}

variable "agent_storage_class" {
  description = "kubernetes storage class to use for agents persistent storage."
}

variable "agent_user" {
  description = "username to access jenkins master."
}

variable "agent_pass" {
  description = "password to access jenkins master."
}

variable "master_url" {
  description = "URL of jenkins master to attach agents to."
}

variable "agent_replicas" {
  description = "number of jenkins agents to create."
}
