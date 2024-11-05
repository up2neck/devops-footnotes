.DEFAULT_GOAL := notebook

SHELL := /bin/bash
RED=\033[0;31m
NC=\033[0m

# Target name message to visually separate targets output
define msg_target_name
	@echo -e "\n[${RED} $@ ${NC}]: executing...\n \
	----------------------------------------"
endef

## Docker ----------------------------------------------------------------------

DOCKER ?= $(shell command -v docker || command -v podman)
DOCKER_WORKDIR ?= /home/jovyan
DOCKER_RUN_OPTS ?= --rm -it -v ${PWD}/src:${DOCKER_WORKDIR}/work:Z \
	-w=${DOCKER_WORKDIR} --userns=keep-id

### Python ---------------------------------------------------------------------
PYTHON_CMD ?= $(shell which python3)
.venv: ### Create Python virtual environment
	$(call msg_target_name)
	${PYTHON_CMD} -m venv ${PWD}/.venv

## Jupyter notebook ------------------------------------------------------------
# https://github.com/jupyter/notebook

NOTEBOOK_DOCKER_IMAGE ?= \
	quay.io/jupyterhub/singleuser:5
DEFAULT_NOTEBOOK ?= work/_welcome.ipynb
NOTEBOOK_ARGS ?= \
	--LabApp.default_url=/lab/tree/${DEFAULT_NOTEBOOK} \
	--NotebookApp.default_url=/tree/${DEFAULT_NOTEBOOK} \
	--ZMQChannelsWebsocketConnection.iopub_data_rate_limit=1.0e10 \
	--IdentityProvider.token='' \
	--log-level=ERROR

.PHONY: notebook
notebook: ### Run jupyter notebook
	$(call msg_target_name)
	${DOCKER} run ${DOCKER_RUN_OPTS} \
		-p 8888:8888 \
		-e NOTEBOOK_ARGS=${NOTEBOOK_ARGS} \
		${NOTEBOOK_DOCKER_IMAGE}

.PHONY: docker-pull
docker-pull: ### Force pull container image for jupyter notebook
	$(call msg_target_name)
	${DOCKER} pull ${NOTEBOOK_DOCKER_IMAGE}

## Generic ---------------------------------------------------------------------

help: ### Show this help.
	@cat ${MAKEFILE_LIST} | sort | sed -ne '/@sed/!s/### /\n\t/p'
