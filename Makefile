NAME         := SnowCrash
ANNOUNCER    := Announcer

ISO_NAME     := SnowCrash.iso
ISO_URL      := https://cdn.intra.42.fr/isos/$(ISO_NAME)
ISO_SIZE     := 378535936

VM_STORE      = $(shell if [ -d "/goinfre/$(USER)" ] && [ -w "/goinfre/$(USER)" ]; \
                    then echo "/goinfre/$(USER)"; \
                    else echo "$${TMPDIR:-/tmp}/$(USER)"; fi)
VM_DIR       ?= $(VM_STORE)/snowcrash-vm
VM_ISO       := $(VM_DIR)/$(ISO_NAME)
VM_PID       := $(VM_DIR)/qemu.pid
VM_MON       := $(VM_DIR)/qemu.sock
VM_LOG       := $(VM_DIR)/qemu.log
VM_KNOWN     := $(VM_DIR)/known_hosts

VM_MEM       ?= 1024
VM_CPUS      ?= 2
VM_SSH_PORT  ?= 4242
VM_DISPLAY   ?= none
VM_BOOT_WAIT ?= 180

LEVEL        ?= level00

VM_ACCEL      = $(shell [ -r /dev/kvm ] && [ -w /dev/kvm ] && echo "-accel kvm -cpu host" || echo "-accel tcg -cpu max")

QEMU         := qemu-system-x86_64
QEMU_FLAGS    = -name $(NAME) $(VM_ACCEL) -m $(VM_MEM) -smp $(VM_CPUS) \
                -cdrom $(VM_ISO) -boot d \
                -netdev user,id=net0,hostfwd=tcp:127.0.0.1:$(VM_SSH_PORT)-:4242 \
                -device e1000,netdev=net0 \
                -display $(VM_DISPLAY) \
                -monitor unix:$(VM_MON),server,nowait \
                -pidfile $(VM_PID) -daemonize

# private known_hosts: the live ISO keeps its host key, but keep it out of ~/.ssh anyway
SSH_OPTS     := -p $(VM_SSH_PORT) \
                -o UserKnownHostsFile=$(VM_KNOWN) \
                -o StrictHostKeyChecking=accept-new \
                -o LogLevel=ERROR
SSH          := ssh $(SSH_OPTS)

get_color = $(if $(filter Purple,$(1)),$(shell tput setaf 5 2>/dev/null),$(if $(filter Red,$(1)),$(shell tput setaf 1 2>/dev/null),$(if $(filter Cyan,$(1)),$(shell tput setaf 6 2>/dev/null),$(if $(filter Blue,$(1)),$(shell tput setaf 4 2>/dev/null),$(if $(filter Yellow,$(1)),$(shell tput setaf 3 2>/dev/null),$(if $(filter Green,$(1)),$(shell tput setaf 2 2>/dev/null),$(shell tput sgr0 2>/dev/null)))))))
ann = $(call get_color,$(1))[$(call get_color,Off)$(ANNOUNCER)$(call get_color,$(1))]$(call get_color,Off)

VM_RUNNING    = [ -f $(VM_PID) ] && kill -0 $$(cat $(VM_PID)) 2>/dev/null

.PHONY: all help vm vm-gui ssh vm-status vm-stop vm-destroy re _vm-store _vm-wait

all: vm ## Boot the VM and wait for SSH (default)

help: ## Show this help
	@echo "$(call ann,Cyan) $(call get_color,Purple)$(NAME)$(call get_color,Off) - available targets:"
	@grep -hE '^[a-zA-Z][a-zA-Z_-]*:.*## ' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN{FS=":.*## "}{printf "  $(call get_color,Green)%-12s$(call get_color,Off) %s\n", $$1, $$2}'
	@echo "  knobs: LEVEL=levelXX VM_SSH_PORT=$(VM_SSH_PORT) VM_MEM=$(VM_MEM) VM_CPUS=$(VM_CPUS) VM_DIR=$(VM_DIR)"

vm: _vm-store $(VM_ISO) ## Boot the SnowCrash ISO headless, SSH forwarded to localhost:4242
	@if $(VM_RUNNING); then \
		echo "$(call ann,Green) $(NAME) is already up (pid $$(cat $(VM_PID))). Nothing to do, my favourite kind of work"; \
	else \
		if ss -Hltn "sport = :$(VM_SSH_PORT)" 2>/dev/null | grep -q .; then \
			echo "$(call ann,Red) Something already squats on port $(VM_SSH_PORT). Kill it or pass VM_SSH_PORT="; \
			exit 1; \
		fi; \
		rm -f $(VM_KNOWN) $(VM_MON); \
		echo "$(call ann,Cyan) Booting $(NAME) on $(word 2,$(VM_ACCEL)). No disk, live ISO, every reboot is a fresh crime scene"; \
		$(QEMU) $(QEMU_FLAGS) 2>$(VM_LOG) || { \
			echo "$(call ann,Red) qemu refused to start. Its last words:"; \
			sed 's/^/    /' $(VM_LOG); \
			exit 1; \
		}; \
	fi
	@$(MAKE) --no-print-directory _vm-wait
	@echo "$(call ann,Green) Alive. make ssh (or ssh $(LEVEL)@localhost -p $(VM_SSH_PORT)), password $(LEVEL) for the first one"

vm-gui: ## Same as vm, but with a window so you can see the login banner
	@$(MAKE) --no-print-directory vm VM_DISPLAY=gtk

ssh: ## SSH into the VM as LEVEL (default level00)
	@$(VM_RUNNING) || { echo "$(call ann,Red) Nothing to talk to yet. make vm first"; exit 1; }
	@echo "$(call ann,Blue) Knocking as $(call get_color,Purple)$(LEVEL)$(call get_color,Off). make ssh LEVEL=levelXX to switch"
	@$(SSH) $(LEVEL)@127.0.0.1

vm-status: ## Tell whether the VM is running
	@if $(VM_RUNNING); then \
		echo "$(call ann,Green) $(NAME) running, pid $$(cat $(VM_PID)), ssh on localhost:$(VM_SSH_PORT)"; \
	else \
		echo "$(call ann,Yellow) $(NAME) is not running"; \
	fi

vm-stop: ## Power off the VM (the ISO stays cached)
	@if $(VM_RUNNING); then \
		echo "$(call ann,Yellow) Pulling the plug on $(NAME). Live ISO, so there was nothing to save anyway"; \
		kill $$(cat $(VM_PID)); \
		for i in $$(seq 50); do $(VM_RUNNING) || break; sleep 0.1; done; \
		if $(VM_RUNNING); then kill -9 $$(cat $(VM_PID)); fi; \
	else \
		echo "$(call ann,Yellow) $(NAME) wasn't running. Stopping it harder changes nothing"; \
	fi
	@rm -f $(VM_PID) $(VM_MON) $(VM_KNOWN)

vm-destroy: vm-stop ## Stop the VM and delete everything, ISO included
	@echo "$(call ann,Red) Shredding $(VM_DIR). The ISO goes too, 361 MiB is a long walk back"
	@rm -rf $(VM_DIR)
	@echo "$(call ann,Green) Gone without a trace. make vm brings it back, none the wiser"

re: ## Reboot the VM from a clean slate
	@echo "$(call ann,Yellow) Rebooting to get the exact same VM back. Cheaper than therapy"
	@$(MAKE) --no-print-directory vm-stop
	@$(MAKE) --no-print-directory vm

_vm-store:
	@command -v $(QEMU) >/dev/null || { echo "$(call ann,Red) No $(QEMU). dnf install qemu-system-x86"; exit 1; }
	@mkdir -p $(VM_DIR) 2>/dev/null || true
	@[ -w "$(VM_DIR)" ] || { echo "$(call ann,Red) $(VM_DIR) won't have me. Point VM_DIR somewhere you own"; exit 1; }
	@r=$$(readlink -f $(VM_DIR)); \
	if [ "$${r#$(HOME)/}" != "$$r" ]; then \
		echo "$(call ann,Red) $(VM_DIR) lands in your home ($$r). 361 MiB of ISO against your quota. Not on my watch"; \
		exit 1; \
	fi

_vm-wait:
	@echo "$(call ann,Blue) Knocking on SSH. Ubuntu 12.04 boots like it's still 2013"
	@for i in $$(seq $(VM_BOOT_WAIT)); do \
		ssh-keyscan -T 2 -p $(VM_SSH_PORT) 127.0.0.1 2>/dev/null | grep -q . && exit 0; \
		$(VM_RUNNING) || { echo "$(call ann,Red) qemu died during boot. See $(VM_LOG)"; exit 1; }; \
		sleep 1; \
	done; \
	echo "$(call ann,Red) No sshd after $(VM_BOOT_WAIT)s. make vm-gui to see what it's doing"; \
	exit 1

$(VM_ISO):
	@mkdir -p $(VM_DIR)
	@echo "$(call ann,Cyan) Pulling $(ISO_NAME), 361 MiB. This is the slow part, go stretch"
	@curl -fL --progress-bar -o $@.part $(ISO_URL)
	@if [ "$$(stat -c %s $@.part)" != "$(ISO_SIZE)" ]; then \
		rm -f $@.part; \
		echo "$(call ann,Red) Size mismatch. Something died in transit, or 42 changed the ISO. I'm not booting that"; \
		exit 1; \
	fi
	@mv $@.part $@
	@echo "$(call ann,Green) Down. No checksum published, so the byte count will have to do"
