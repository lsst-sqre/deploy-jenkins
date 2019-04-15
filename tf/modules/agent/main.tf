locals {
  agent_uid    = "888"
  agent_gid    = "${local.agent_uid}"
  agent_fsroot = "/j"
}

resource "kubernetes_secret" "jenkins_agent" {
  metadata {
    namespace = "${var.k8s_namespace}"
    name      = "${var.name}"

    labels {
      app  = "jenkins"
      role = "agent"
    }
  }

  data {
    JSWARM_USERNAME = "${var.agent_user}"
    JSWARM_PASSWORD = "${var.agent_pass}"
  }
}

# headless service required by statefulset
resource "kubernetes_service" "jenkins_agent" {
  metadata {
    namespace = "${var.k8s_namespace}"
    name      = "${var.name}"

    labels {
      app  = "jenkins"
      role = "agent"
    }
  }

  spec {
    selector {
      name = "${var.name}"
      app  = "jenkins"
      role = "agent"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "jenkins_agent" {
  metadata {
    namespace = "${var.k8s_namespace}"
    name      = "${var.name}"

    labels {
      app  = "jenkins"
      role = "agent"
    }
  }

  spec {
    pod_management_policy  = "OrderedReady"
    replicas               = "${var.agent_replicas}"
    revision_history_limit = 10

    selector {
      match_labels {
        name = "${var.name}"
        app  = "jenkins"
        role = "agent"
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
          name = "${var.name}"
          app  = "jenkins"
          role = "agent"
        }
      }

      spec {
        container {
          name              = "dind-daemon"
          image             = "docker:18.09.5-dind"
          image_pull_policy = "Always"

          security_context {
            privileged = true
          }

          volume_mount {
            name       = "docker-graph-storage"
            mount_path = "/var/lib/docker"
          }

          volume_mount {
            name       = "ws"
            mount_path = "${local.agent_fsroot}"
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
              value = "${var.master_url}"
            },
            {
              name  = "JSWARM_MODE"
              value = "normal"
            },
            {
              name  = "JSWARM_LABELS"
              value = "${join(" ", var.agent_labels)}"
            },
            {
              name  = "JSWARM_EXECUTORS"
              value = "${var.agent_executors}"
            },
            {
              name = "JSWARM_AGENT_NAME"

              value_from {
                field_ref {
                  field_path = "metadata.name"
                }
              }
            },
            {
              name  = "JSWARM_DISABLE_CLIENTS_UNIQUE_ID"
              value = "true"
            },
            {
              name  = "JSWARM_DELETE_EXISTING_CLIENTS"
              value = "true"
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
            name       = "ws"
            mount_path = "${local.agent_fsroot}"
          }
        } # container

        init_container {
          name              = "mount-chown"
          image             = "alpine:3.9"
          image_pull_policy = "IfNotPresent"
          command           = ["sh", "-c", "chown 888:888 ${local.agent_fsroot} && chmod 6700 ${local.agent_fsroot}"]

          volume_mount {
            name       = "ws"
            mount_path = "${local.agent_fsroot}"
          }
        }

        volume {
          name      = "docker-graph-storage"
          empty_dir = {}
        }
      } # spec
    } # template

    volume_claim_template {
      metadata {
        name = "ws"
      }

      spec {
        access_modes = ["ReadWriteOnce"]

        #storage_class_name = "${kubernetes_storage_class.gp2.metadata.0.name}"
        storage_class_name = "${var.agent_storage_class}"

        resources {
          requests {
            storage = "${var.agent_volume_size}"
          }
        }
      }
    }
  } # spec
}
