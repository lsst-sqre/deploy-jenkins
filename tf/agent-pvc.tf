resource "kubernetes_persistent_volume_claim" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "jenkins-agent"

    labels {
      app = "jenkins"
    }
  }

  spec {
    access_modes       = ["ReadWriteOnce"]
    storage_class_name = "${kubernetes_storage_class.gp2.metadata.0.name}"

    resources {
      requests {
        storage = "${var.jenkins_agent_volume_size}"
      }
    }
  }
}
