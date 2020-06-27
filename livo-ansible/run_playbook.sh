#!/bin/bash

ansible-playbook site.yml -i hosts --ask-vault-pass --ask-sudo-pass $@
