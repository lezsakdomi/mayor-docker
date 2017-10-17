.DEFAULT_GOAL:=build
IMAGE_NAME:=mayor
IMAGE_TAG:=latest

DOCKER_EXTRA_ARGS:=
DOCKER_BUILD_EXTRA_ARGS:=
DOCKER_RUN_EXTRA_ARGS:=
DOCKER_EXEC_EXTRA_ARGS:=
DOCKER_STOP_EXTRA_ARGS:=
DOCKER_START_EXTRA_ARGS:=

# Used here
SHELL:=bash # The shell to invoke on `make shell`
OPEN_PORTS:=80 443 # Open these ports on `make run`
DOCKER_RUN_COMMAND:= # For Dockerfiles wich don't have `CMD` yet :)
KEEP_CONTAINER:= # Don't clean up the container across rebuilds

m4_defines=DEFAULT_INIT BASE_ONLY NO_SSL USE_CERTBOT NO_HOSTNAME_SETUP
DEFAULT_INIT:= # Keep the default init system
BASE_ONLY:= # Don't install naplo module
NO_SSL:= # Don't setup SSL
USE_CERTBOT:= # Use certbot for ssling (means a not-self-signed-cert :) ) (Beta, use on your own responsibility)
NO_HOSTNAME_SETUP:= # Don't set up hostname (means localhost at most case) (not recommended)

docker_build-args=HOSTNAME php_memory_limit VERSION PREFIX INSTALLDIR MYSQL_ROOT_PASSWORD
HOSTNAME:=$(shell ip addr | grep -Po '(?<=inet )192.168.\d+.\d+' || echo localhost) # See $(NO_HOSTNAME_SETUP) :)
php_memory_limit:= # Included into php.ini
VERSION:= # MaYoR version to dl & install
PREFIX:= # To specify install location
INSTALLDIR:= # To be appended to `PREFIX`
MYSQL_ROOT_PASSWORD:= # Warning! To be exported as envvar in target docker image!

# Helpers
tmp_image_tag=$(IMAGE_NAME):tmp-$(shell date +%s.%N)
docker_build_args=$(foreach arg,$(docker_build-args),$(if $($(arg)),--build-arg $(arg)=$($(arg)))) $(DOCKER_EXTRA_ARGS) $(DOCKER_BUILD_EXTRA_ARGS)
docker_run_args=-d $(foreach port,$(OPEN_PORTS),-p $(port):$(port)) $(DOCKER_EXTRA_ARGS) $(DOCKER_EXTRA_RUN_ARGS)
docker_exec_args=-it $(DOCKER_EXTRA_ARGS) $(DOCKER_EXEC_EXTRA_ARGS)
docker_stop_args=$(DOCKER_EXTRA_ARGS) $(DOCKER_STOP_EXTRA_ARGS)
docker_start_args=$(DOCKER_EXTRA_ARGS) $(DOCKER_START_EXTRA_ARGS)
image_id_file=.daemon.image.ref
container_id_file=.daemon.container.ref

m4_args=--prefix-builtins $(foreach define,$(m4_defines),$(if $($(define)),-D $(define)=$($(define))))
%: %.m4
	m4 $(m4_args) $< >$@

.PHONY: build
build: $(image_id_file)

.PHONY: install
install: tag

.PHONY: tag
tag: $(image_id_file)
	docker tag `cat $(image_id_file)` $(IMAGE_NAME):$(IMAGE_TAG) $(DOCKER_EXTRA_ARGS)

.PHONY: run
run: $(container_id_file)

stop_target_name=stop
.PHONY: $(stop_target_name)
$(stop_target_name): | $(container_id_file)
	docker stop $(docker_stop_args) `cat $(container_id_file)`

restart_target_name=restart
.PHONY: $(restart_target_name)
$(restart_target_name): | $(container_id_file)
	docker restart $(docker_stop_args) `cat $(container_id_file)`

start_target_name=start
.PHONY: $(start_target_name)
$(start_target_name): | $(container_id_file)
	docker start $(docker_start_args) `cat $(container_id_file)`

.PHONY: shell
shell: $(container_id_file)
	docker exec $(docker_exec_args) `cat $(container_id_file)` $(SHELL)


.PHONY: clean
clean: clean-container clean-image
	if [ -f Dockerfile ]; then rm Dockerfile; fi

.PHONY: mostlyclean
mostlyclean: clean-container
	@rm -f $(container_id_file) $(image_id_file)

.PHONY: clean-container
clean-container:
	if [ -f $(container_id_file) ]; then \
		docker rm -f `cat $(container_id_file)` \
		&& rm $(container_id_file); \
	fi

.PHONY: clean-image
clean-image:
	if [ -f $(image_id_file) ]; then \
		docker rmi -f `cat $(image_id_file)` \
		&& rm $(image_id_file); \
	fi


$(container_id_file): $(image_id_file)
	if [ -f "$@" ] && [ "$(KEEP_CONTAINER)"=="" ]; then docker rm -f `cat $<`; fi
	docker run $(docker_run_args) `cat $<` $(DOCKER_RUN_COMMAND) >$@

stored_tag:=$(tmp_image_tag)
$(image_id_file): Dockerfile
	docker build $(docker_build_args) -t $(stored_tag) .
	echo $(stored_tag) >$@
#	docker images -q $(stored_tag) >$@
