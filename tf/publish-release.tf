data "terraform_remote_state" "pr" {
  backend = "s3"

  config {
    region = "${var.aws_default_region}"
    bucket = "${data.template_file.publish_release_bucket.rendered}"
    key    = "terraform.tfstate"
  }
}

output "DOXYGEN_FQDN" {
  value = "${data.terraform_remote_state.pr.DOXYGEN_FQDN}"
}

output "DOXYGEN_S3_BUCKET" {
  value = "${data.terraform_remote_state.pr.DOXYGEN_S3_BUCKET}"
}

output "DOXYGEN_PUSH_USER" {
  value = "${data.terraform_remote_state.pr.DOXYGEN_PUSH_USER}"
}

output "DOXYGEN_PUSH_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.DOXYGEN_PUSH_AWS_ACCESS_KEY_ID}"
}

output "DOXYGEN_PUSH_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.DOXYGEN_PUSH_AWS_SECRET_ACCESS_KEY}"
}

output "EUPS_FQDN" {
  value = "${data.terraform_remote_state.pr.EUPS_FQDN}"
}

output "EUPS_S3_BUCKET" {
  value = "${data.terraform_remote_state.pr.EUPS_S3_BUCKET}"
}

output "EUPS_PUSH_USER" {
  value = "${data.terraform_remote_state.pr.EUPS_PUSH_USER}"
}

output "EUPS_PUSH_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_PUSH_AWS_ACCESS_KEY_ID}"
}

output "EUPS_PUSH_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_PUSH_AWS_SECRET_ACCESS_KEY}"
}

output "EUPS_PULL_USER" {
  value = "${data.terraform_remote_state.pr.EUPS_PULL_USER}"
}

output "EUPS_PULL_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_PULL_AWS_ACCESS_KEY_ID}"
}

output "EUPS_PULL_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_PULL_AWS_ACCESS_KEY_ID}"
}

output "EUPS_BACKUP_S3_BUCKET" {
  value = "${data.terraform_remote_state.pr.EUPS_BACKUP_S3_BUCKET}"
}

output "EUPS_BACKUP_USER" {
  value = "${data.terraform_remote_state.pr.EUPS_BACKUP_USER}"
}

output "EUPS_BACKUP_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_BACKUP_AWS_ACCESS_KEY_ID}"
}

output "EUPS_BACKUP_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_BACKUP_AWS_SECRET_ACCESS_KEY}"
}

output "EUPS_TAG_ADMIN_USER" {
  value = "${data.terraform_remote_state.pr.EUPS_TAG_ADMIN_USER}"
}

output "EUPS_TAG_ADMIN_AWS_ACCESS_KEY_ID" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_TAG_ADMIN_AWS_ACCESS_KEY_ID}"
}

output "EUPS_TAG_ADMIN_AWS_SECRET_ACCESS_KEY" {
  sensitive = true
  value     = "${data.terraform_remote_state.pr.EUPS_TAG_ADMIN_AWS_SECRET_ACCESS_KEY}"
}
