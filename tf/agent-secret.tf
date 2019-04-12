resource "kubernetes_secret" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "jenkins-agent"

    labels {
      app = "jenkins"
    }
  }

  data {
    JSWARM_USERNAME = "${var.jenkins_agent_user}"
    JSWARM_PASSWORD = "${var.jenkins_agent_pass}"
  }
}
