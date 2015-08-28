BIN_DIR=./bin
ZIP_FILE=terraform_0.6.3_linux_amd64.zip

$(BIN_DIR):
	mkdir $@
	cd $@; wget -nc https://dl.bintray.com/mitchellh/terraform/$(ZIP_FILE)
	cd $@; unzip $(ZIP_FILE)
