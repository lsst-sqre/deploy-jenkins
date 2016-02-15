BIN_DIR=./bin
TF_VERSION=0.6.3
ZIP_FILE=terraform_$(TF_VERSION)_linux_amd64.zip

$(BIN_DIR):
	mkdir $@
	cd $@; wget -nc https://releases.hashicorp.com/terraform/$(TF_VERSION)/$(ZIP_FILE)
	cd $@; unzip $(ZIP_FILE)
