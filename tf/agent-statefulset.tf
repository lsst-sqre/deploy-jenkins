resource "kubernetes_service" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "jenkins-agent"

    labels {
      app = "jenkins"
    }
  }

  spec {
    selector {
      app = "jenkins"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "jenkins-agent"

    labels {
      app = "jenkins"
    }
  }

  spec {
    pod_management_policy  = "OrderedReady"
    replicas               = 3
    revision_history_limit = 10

    selector {
      match_labels {
        name = "jenkins-agent"
        app  = "jenkins"
      }
    }

    service_name = "${kubernetes_service.jenkins_agent.metadata.0.name}"

    update_strategy {
      type = "RollingUpdate"

      #rolling_update {
      #  max_surge       = "${ceil(var.replicas * 1.5)}"
      #  max_unavailable = "${floor(var.replicas * 0.5)}"
      #}
    }

    template {
      metadata {
        labels {
          name = "jenkins-agent"
          app  = "jenkins"
        }
      }

      spec {
        container {
          name              = "dind-daemon"
          image             = "docker:18.06.1-dind"
          image_pull_policy = "Always"

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "docker-graph-storage"
            mount_path = "/var/lib/docker"
          }

          volume_mount {
            name       = "jenkins-agent"
            mount_path = "/j"
          }

          # https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container
          #resources {
          #  limits {
          #    cpu    = "0.5"
          #    memory = "512Mi"
          #  }

          #  requests {
          #    cpu    = "0.25"
          #    memory = "256Mi"
          #  }
          #}

          ## https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/
          #liveness_probe {
          #  http_get {
          #    path = "/"
          #    port = "80"
          #  }

          #  initial_delay_seconds = "30"
          #  timeout_seconds       = "5"
          #  period_seconds        = "10"
          #}

          #readiness_probe {
          #  http_get {
          #    path = "/"
          #    port = "80"
          #  }

          #  initial_delay_seconds = "1"
          #  timeout_seconds       = "2"
          #  period_seconds        = "10"
          #}
        } # container

        container {
          name              = "swarm"
          image             = "lsstsqre/jenkins-swarm-client:latest"
          image_pull_policy = "Always"

          env = [
            {
              name  = "DOCKER_HOST"
              value = "tcp://localhost:2375"
            },
            {
              name  = "MASTER_URL"
              value = "https://${local.master_alias}"
            },
            {
              name  = "JENKINS_SLAVE_MODE"
              value = "normal"
            },
            {
              name  = "LABELS"
              value = "docker"
            },
            {
              name  = "EXECUTORS"
              value = "1"
            },
            {
              name  = "CLIENT_NAME"
              value = "agent"
            },
            {
              name  = "FSROOT"
              value = "/j"
            },
            {
              name  = "DISABLE_CLIENTS_UNIQUE_ID"
              value = false
            },
            {
              name  = "DELETE_EXISTING_CLIENTS"
              value = true
            },
          ]

          env {
            name = "JENKINS_USERNAME"

            value_from {
              secret_key_ref {
                name = "${kubernetes_secret.jenkins_agent.metadata.0.name}"
                key  = "JENKINS_USERNAME"
              }
            }
          }

          env {
            name = "JENKINS_PASSWORD"

            value_from {
              secret_key_ref {
                name = "${kubernetes_secret.jenkins_agent.metadata.0.name}"
                key  = "JENKINS_PASSWORD"
              }
            }
          }

          volume_mount {
            name       = "jenkins-agent"
            mount_path = "/j"
          }
        } # container

        volume {
          name      = "docker-graph-storage"
          empty_dir = {}
        }
      } # spec
    } # template

    volume_claim_template {
      metadata {
        name = "jenkins-agent"
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
  } # spec
}
