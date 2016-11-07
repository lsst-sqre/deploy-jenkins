UNAME := $(shell uname -s | tr A-Z a-z)
BIN_DIR=./bin
TF_VERSION=0.6.16
ZIP_FILE=terraform_$(TF_VERSION)_$(UNAME)_amd64.zip

$(BIN_DIR):
	mkdir $@
	cd $@; wget -nc https://releases.hashicorp.com/terraform/$(TF_VERSION)/$(ZIP_FILE)
	cd $@; unzip $(ZIP_FILE)

define ENV_TEMPLATE
$(1): env/$(1).tf
	-cp $$< override.tf
endef

define OPT_TEMPLATE
$(1): opt/$(1).tf
	-cp $$< $(1).tf

no$(1):
	-rm $(1).tf
endef

$(eval $(call ENV_TEMPLATE,dev))
$(eval $(call ENV_TEMPLATE,prod))
$(eval $(call OPT_TEMPLATE,rds))

clean:
	-rm -rf bin override.tf
