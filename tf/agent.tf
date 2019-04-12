resource "kubernetes_secret" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "agent"

    labels {
      app = "jenkins"
    }
  }

  data {
    JSWARM_USERNAME = "${var.jenkins_agent_user}"
    JSWARM_PASSWORD = "${var.jenkins_agent_pass}"
  }
}

resource "kubernetes_service" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "agent"

    labels {
      app = "jenkins"
    }
  }

  spec {
    selector {
      name = "agent"
      app  = "jenkins"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "jenkins_agent" {
  metadata {
    namespace = "${kubernetes_namespace.jenkins.metadata.0.name}"
    name      = "agent"

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
        name = "agent"
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
          name = "agent"
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
            name       = "agent-ws"
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
              name  = "JSWARM_MASTER_URL"
              value = "https://${local.master_alias}"
            },
            {
              name  = "JSWARM_MODE"
              value = "normal"
            },
            {
              name  = "JSWARM_LABELS"
              value = "docker"
            },
            {
              name  = "JSWARM_EXECUTORS"
              value = "1"
            },
            {
              name  = "JSWARM_AGENT_NAME"
              value_from {
                field_ref {
                  field_path = "metadata.name"
                }
              }
            },
            {
              name  = "JSWARM_DISABLE_CLIENTS_UNIQUE_ID"
              value = false
            },
            {
              name  = "JSWARM_DELETE_EXISTING_CLIENTS"
              value = true
            },
            {
              name = "JSWARM_USERNAME"
              value_from {
                secret_key_ref {
                  name = "${kubernetes_secret.jenkins_agent.metadata.0.name}"
                  key  = "JSWARM_USERNAME"
                }
              }
            },
            {
              name = "JSWARM_PASSWORD"
              value_from {
                secret_key_ref {
                  name = "${kubernetes_secret.jenkins_agent.metadata.0.name}"
                  key  = "JSWARM_PASSWORD"
                }
              }
            },
          ]

          volume_mount {
            name       = "agent-ws"
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
        name = "agent-ws"
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
