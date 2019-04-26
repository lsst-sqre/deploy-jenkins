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

variable "agent_labels" {
  description = "number of jenkins agents to create."
  default     = []
}

variable "agent_executors" {
  description = "number of executors per agent."
  default     = "1"
}

variable "agent_mode" {
  description = "agent user mode: \"normal\" or \"exclusive\"."
  default     = "normal"
}

variable "agent_uid" {
  description = "swarm agent uid"
  default     = "888"
}

variable "agent_gid" {
  description = "swarm agent gid"
  default     = "888"
}

variable "dind_image" {
  description = "DinD docker image."
  default     = "docker:18.09.5-dind"
}

variable "swarm_image" {
  description = "jenkins swarm docker image."
  default     = "lsstsqre/jenkins-swarm-client:latest"
}
