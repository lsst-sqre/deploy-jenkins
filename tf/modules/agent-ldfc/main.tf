locals {
  agent_fsroot     = "/j"
  app_name         = "jenkins"
  app_version      = "1.0.0"
  dockergc_grace   = "3600"
  docker_host_name = "localhost"
  docker_host_port = "2375"
  docker_host      = "tcp://${local.docker_tuple}"
  docker_tuple     = "${local.docker_host_name}:${local.docker_host_port}"
  jmx_host         = "localhost"
  jmx_port         = "8080"
  jmx_tuple        = "${local.jmx_host}:${local.jmx_port}"
}

resource "kubernetes_secret" "jenkins_agent" {
  metadata {
    namespace = "${var.k8s_namespace}"
    name      = "${var.name}"

    labels {
      "app.k8s.io/name"       = "${var.name}"
      "app.k8s.io/instance"   = "${var.env_name}"
      "app.k8s.io/version"    = "${local.app_version}"
      "app.k8s.io/component"  = "agent"
      "app.k8s.io/part-of"    = "jenkins"
      "app.k8s.io/managed-by" = "terraform"
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
      "app.k8s.io/name"       = "${var.name}"
      "app.k8s.io/instance"   = "${var.env_name}"
      "app.k8s.io/version"    = "${local.app_version}"
      "app.k8s.io/component"  = "agent"
      "app.k8s.io/part-of"    = "jenkins"
      "app.k8s.io/managed-by" = "terraform"
    }
  }

  spec {
    selector {
      "app.k8s.io/name"      = "${var.name}"
      "app.k8s.io/instance"  = "${var.env_name}"
      "app.k8s.io/version"   = "${local.app_version}"
      "app.k8s.io/component" = "agent"
      "app.k8s.io/part-of"   = "jenkins"
    }

    cluster_ip = "None"
  }
}

resource "kubernetes_stateful_set" "jenkins_agent" {
  metadata {
    namespace = "${var.k8s_namespace}"
    name      = "${var.name}"

    labels {
      "app.k8s.io/name"       = "${var.name}"
      "app.k8s.io/instance"   = "${var.env_name}"
      "app.k8s.io/version"    = "${local.app_version}"
      "app.k8s.io/component"  = "agent"
      "app.k8s.io/part-of"    = "jenkins"
      "app.k8s.io/managed-by" = "terraform"
    }
  }

  spec {
    pod_management_policy  = "Parallel"
    replicas               = "${var.agent_replicas}"
    revision_history_limit = 10

    selector {
      match_labels {
        "app.k8s.io/name"      = "${var.name}"
        "app.k8s.io/instance"  = "${var.env_name}"
        "app.k8s.io/version"   = "${local.app_version}"
        "app.k8s.io/component" = "agent"
        "app.k8s.io/part-of"   = "jenkins"
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
          "app.k8s.io/name"       = "${var.name}"
          "app.k8s.io/instance"   = "${var.env_name}"
          "app.k8s.io/version"    = "${local.app_version}"
          "app.k8s.io/component"  = "agent"
          "app.k8s.io/part-of"    = "jenkins"
          "app.k8s.io/managed-by" = "terraform"
        }
      }

      spec {
        security_context {
          # intended primary for dind; can not set fs_group at container level
          fs_group = "${var.agent_gid}"
        }

        affinity {
          node_affinity {
            required_during_scheduling_ignored_during_execution {
              node_selector_term {
                match_expressions {
                  key      = "kubernetes.io/hostname"
                  operator = "NotIn"
                  values   = ["lsst-kub005", "lsst-kub017"]
                }
              }
            }
          }
        }

        container {
          name              = "dind"
          image             = "${var.dind_image}"
          image_pull_policy = "Always"
          command           = ["/usr/local/bin/dockerd"]
          args              = ["--host=${local.docker_host}", "--mtu=1376"]

          security_context {
            privileged = true
          }

          env {
            name  = "DOCKER_HOST"
            value = "${local.docker_host}"
          }

          volume_mount {
            name       = "docker-graph-storage"
            mount_path = "/var/lib/docker"
          }

          volume_mount {
            name       = "ws"
            mount_path = "${local.agent_fsroot}"
          }

          resources {
            limits {
              cpu    = "32"
              memory = "96Gi"
            }

            requests {
              cpu    = "6"
              memory = "12Gi"
            }
          }

          liveness_probe {
            exec {
              command = [
                "wget",
                "--spider",
                "-q",
                "http://${local.docker_tuple}/_ping",
              ]
            }

            initial_delay_seconds = "5"
            timeout_seconds       = "1"
            period_seconds        = "5"
            failure_threshold     = "2"
          }

          readiness_probe {
            exec {
              command = [
                "wget",
                "--spider",
                "-q",
                "http://${local.docker_tuple}/_ping",
              ]
            }

            initial_delay_seconds = "5"
            timeout_seconds       = "1"
            period_seconds        = "5"
            failure_threshold     = "2"
          }
        } # container

        container {
          name              = "docker-gc"
          image             = "${var.dockergc_image}"
          image_pull_policy = "Always"
          command           = ["sh", "-c", "while true; do /usr/local/bin/docker-gc; sleep $GRACE_PERIOD_SECONDS; done"]

          security_context {
            # docker-gc writes to /var by default
            run_as_user = "0"
          }

          env {
            name  = "DOCKER_HOST"
            value = "${local.docker_host}"
          }

          env {
            name  = "GRACE_PERIOD_SECONDS"
            value = "${local.dockergc_grace}"
          }

          env {
            name  = "MINIMUM_IMAGES_TO_SAVE"
            value = "5"
          }

          env {
            name  = "REMOVE_VOLUMES"
            value = "1"
          }

          env {
            name  = "FORCE_CONTAINER_REMOVAL"
            value = "1"
          }

          env {
            name  = "FORCE_IMAGE_REMOVAL"
            value = "1"
          }

          resources {
            limits {
              cpu    = "500m"
              memory = "512Mi"
            }

            requests {
              cpu    = "200m"
              memory = "100Mi"
            }
          }
        } # container

        container {
          name              = "swarm"
          image             = "${var.swarm_image}"
          image_pull_policy = "Always"

          security_context {
            run_as_user = "${var.agent_uid}"

            # k8s 1.14+
            run_as_group = "${var.agent_gid}"
          }

          liveness_probe {
            exec {
              command = [
                "wget",
                "--spider",
                "-q",
                "http://${local.jmx_tuple}/metrics",
              ]
            }

            initial_delay_seconds = "5"
            timeout_seconds       = "1"
            period_seconds        = "5"
            failure_threshold     = "2"
          }

          readiness_probe {
            exec {
              command = [
                "wget",
                "--spider",
                "-q",
                "http://${local.jmx_tuple}/metrics",
              ]
            }

            initial_delay_seconds = "5"
            timeout_seconds       = "1"
            period_seconds        = "5"
            failure_threshold     = "2"
          }

          resources {
            limits {
              cpu    = "2"
              memory = "3Gi"
            }

            requests {
              cpu    = "1"
              memory = "2Gi"
            }
          }

          env = [
            {
              name  = "DOCKER_HOST"
              value = "${local.docker_host}"
            },
            {
              name  = "JSWARM_MASTER_URL"
              value = "${var.master_url}"
            },
            {
              name  = "JSWARM_MODE"
              value = "${var.agent_mode}"
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
        access_modes = ["ReadWriteMany"]

        resources {
          requests {
            storage = "${var.agent_volume_size}"
          }
        }

        selector {
          match_labels {
            "app.k8s.io/name"      = "${var.name}"
            "app.k8s.io/instance"  = "${var.env_name}"
            "app.k8s.io/version"   = "${local.app_version}"
            "app.k8s.io/component" = "agent"
            "app.k8s.io/part-of"   = "jenkins"
          }
        }
      }
    }
  } # spec
}

resource "kubernetes_persistent_volume" "jenkins_agent_ws" {
  count = "${var.agent_replicas}"

  metadata {
    name = "${local.app_name}-${var.env_name}-ws-${count.index}"

    labels {
      "app.k8s.io/name"       = "${var.name}"
      "app.k8s.io/instance"   = "${var.env_name}"
      "app.k8s.io/version"    = "${local.app_version}"
      "app.k8s.io/component"  = "agent"
      "app.k8s.io/part-of"    = "jenkins"
      "app.k8s.io/managed-by" = "terraform"
    }
  }

  spec {
    capacity {
      storage = "1500Gi"
    }

    access_modes = ["ReadWriteMany"]

    mount_options = ["local_lock=all"]

    persistent_volume_source {
      nfs {
        path   = "/lsst/project/${local.app_name}/${var.env_name}/${var.name}-ws-${count.index}"
        server = "lsst-nfs.ncsa.illinois.edu"
      }
    }
  }
}
