UNAME := $(shell uname -s | tr A-Z a-z)
BIN_DIR = bin
DL_DIR = downloads
ARCH = amd64
TF_PLUG_DIR := .terraform/plugins/$(UNAME)_$(ARCH)

TF_VER = 0.11.14
TF_ZIP_FILE := terraform_$(TF_VER)_$(UNAME)_$(ARCH).zip
TF_ZIP_DL := $(DL_DIR)/$(TF_ZIP_FILE)
TF_BIN := $(BIN_DIR)/terraform

ndef = $(if $(value $(1)),,$(error $(1) not set))

# these default values must be in sync with the definitions variables.tf
TF_VAR_env_name ?= $(call ndef, TF_VAR_env_name)
TF_VAR_service_name ?= $(call ndef, TF_VAR_service_name)
TF_VAR_domain_name ?= $(call ndef, TF_VAR_domain_name)
AWS_DEFAULT_REGION ?= $(call ndef, AWS_DEFAULT_REGION)

dns_prefix := $(subst jenkins-prod-,,$(TF_VAR_env_name)-)
FQDN := $(dns_prefix)$(TF_VAR_service_name).$(TF_VAR_domain_name)
TF_S3_BCKT := $(FQDN)-tf

.PHONY: all test
all: tf-install
test: tf-test

# $< may not be defined because of |
$(TF_BIN): | $(TF_ZIP_DL)
	unzip -d $(BIN_DIR) $(TF_ZIP_DL)

$(TF_ZIP_DL): | $(DL_DIR)
	wget -nc https://releases.hashicorp.com/terraform/$(TF_VER)/$(TF_ZIP_FILE) -O $@

$(BIN_DIR) $(DL_DIR) $(TF_PLUG_DIR):
	mkdir -p $@

.PHONY: tf-install
tf-install: $(TF_BIN)

.PHONY: tf-s3-mb
tf-s3-mb:
	aws s3 mb s3://$(TF_S3_BCKT) --region $(AWS_DEFAULT_REGION)

.PHONY: tf-init-s3
tf-init-s3: tf-install tf-s3-mb
	$(TF_BIN) init \
		-backend=true \
		-backend-config="region=$(AWS_DEFAULT_REGION)" \
		-backend-config="bucket=$(TF_S3_BCKT)" \
		-backend-config="key=terraform.tfstate" \
		-input=false \
		-upgrade=true \
		-get=true \
		-reconfigure \
		-force-copy

.PHONY: tf-init
tf-init: tf-install
	$(TF_BIN) init \
		-backend=false \
		-upgrade=true \
		-get=true

.PHONY: tf-test
tf-test: tf-init tf-fmt tf-validate

.PHONY: tf-fmt
tf-fmt:
	$(TF_BIN) fmt --check=true --diff=true

.PHONY: tf-validate
tf-validate:
	$(TF_BIN) validate --check-variables=false

.PHONY: clean
clean:
	-rm -rf $(BIN_DIR)
