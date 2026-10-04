# Toolbox VM: throwaway Debian with every external tool we used, minus IDA.
# Reaches the target through the host gateway: ssh -p 4242 level00@10.0.2.2
# Storage, QEMU, VM_ACCEL and the announcer come from the main Makefile.

TB_NAME      := snowcrash-toolbox
TB_DIR       ?= $(VM_STORE)/snowcrash-toolbox
TB_TMPL      := mk/toolbox

TB_MEM       ?= 2048
TB_CPUS      ?= 2
TB_DISK_SZ   ?= 12G
TB_SSH_PORT  ?= 2223
TB_USER      ?= $(USER)

DEBIAN_REL   ?= trixie
DEBIAN_IMG   := debian-13-genericcloud-amd64.qcow2
DEBIAN_URL   := https://cloud.debian.org/images/cloud/$(DEBIAN_REL)/latest/$(DEBIAN_IMG)
DEBIAN_SUMS  := https://cloud.debian.org/images/cloud/$(DEBIAN_REL)/latest/SHA512SUMS

TB_BASE      := $(TB_DIR)/$(DEBIAN_IMG)
TB_DISK      := $(TB_DIR)/$(TB_NAME).qcow2
TB_SEED      := $(TB_DIR)/seed.iso
TB_KEY       := $(TB_DIR)/id_ed25519
TB_SSHCFG    := $(TB_DIR)/ssh_config
TB_PID       := $(TB_DIR)/qemu.pid
TB_MON       := $(TB_DIR)/qemu.sock
TB_LOG       := $(TB_DIR)/qemu.log

TB_HOST_UID  := $(shell id -u)
TB_HOST_GID  := $(shell id -g)

TB_MKISO     ?= $(firstword $(foreach b,xorrisofs genisoimage mkisofs,$(shell command -v $(b) 2>/dev/null)))

TB_RUNNING    = [ -f $(TB_PID) ] && kill -0 $$(cat $(TB_PID)) 2>/dev/null
TB_SSH        = ssh -F $(TB_SSHCFG) toolbox

TB_RENDER = sed \
	-e 's|@TB_USER@|$(TB_USER)|g' \
	-e 's|@HOST_UID@|$(TB_HOST_UID)|g' \
	-e 's|@HOST_GID@|$(TB_HOST_GID)|g'

.PHONY: toolbox toolbox-ssh toolbox-sync toolbox-status toolbox-stop toolbox-destroy _tb-store _tb-wait

toolbox: _tb-store $(TB_DISK) $(TB_SEED) $(TB_SSHCFG) ## Boot the toolbox VM (john, tshark, gdb, ...) and wait for SSH
	@if $(TB_RUNNING); then \
		echo "$(call ann,Green) $(TB_NAME) is already up (pid $$(cat $(TB_PID))). Nothing to do"; \
	else \
		if ss -Hltn "sport = :$(TB_SSH_PORT)" 2>/dev/null | grep -q .; then \
			echo "$(call ann,Red) Something already squats on port $(TB_SSH_PORT). Pass TB_SSH_PORT="; \
			exit 1; \
		fi; \
		rm -f $(TB_MON); \
		echo "$(call ann,Cyan) Booting $(TB_NAME) on $(word 2,$(VM_ACCEL)). First boot runs cloud-init + apt, so go make coffee"; \
		$(QEMU) -name $(TB_NAME) $(VM_ACCEL) -m $(TB_MEM) -smp $(TB_CPUS) \
			-drive file=$(TB_DISK),if=virtio \
			-cdrom $(TB_SEED) \
			-netdev user,id=n0,hostfwd=tcp:127.0.0.1:$(TB_SSH_PORT)-:22 \
			-device virtio-net-pci,netdev=n0 \
			-display none \
			-monitor unix:$(TB_MON),server,nowait \
			-pidfile $(TB_PID) -daemonize 2>$(TB_LOG) || { \
				echo "$(call ann,Red) qemu refused to start. Its last words:"; \
				sed 's/^/    /' $(TB_LOG); \
				exit 1; \
			}; \
	fi
	@$(MAKE) --no-print-directory _tb-wait
	@$(MAKE) --no-print-directory toolbox-sync
	@echo "$(call ann,Green) Toolbox up. make toolbox-ssh to get in"
	@echo "$(call ann,Blue)   target from inside: ssh -p 4242 level00@10.0.2.2 (through the host)"
	@echo "$(call ann,Blue)   project copy:       ~/snowcrash (refresh it with make toolbox-sync)"

toolbox-ssh: ## Open a shell in the toolbox VM (lands in ~/snowcrash)
	@$(TB_RUNNING) || { echo "$(call ann,Red) No toolbox running. make toolbox first"; exit 1; }
	@$(TB_SSH) -t 'cd ~/snowcrash 2>/dev/null; exec $$SHELL -l'

toolbox-sync: ## Copy the project tree into the toolbox at ~/snowcrash (minus .git and IDA dbs)
	@$(TB_RUNNING) || { echo "$(call ann,Red) No toolbox running. make toolbox first"; exit 1; }
	@echo "$(call ann,Cyan) Copying the project into the toolbox at ~/snowcrash"
	@tar -C $(CURDIR) --exclude=.git --exclude='*.id0' --exclude='*.id1' \
		--exclude='*.id2' --exclude='*.nam' --exclude='*.til' -czf - . \
		| $(TB_SSH) 'rm -rf ~/snowcrash && mkdir -p ~/snowcrash && tar -xzf - -C ~/snowcrash'
	@echo "$(call ann,Green) Synced. It's all in ~/snowcrash in the toolbox"

toolbox-status: ## Tell whether the toolbox VM is running
	@if $(TB_RUNNING); then \
		echo "$(call ann,Green) $(TB_NAME) running, pid $$(cat $(TB_PID)), ssh on localhost:$(TB_SSH_PORT)"; \
	else \
		echo "$(call ann,Yellow) $(TB_NAME) is not running"; \
	fi

toolbox-stop: ## Power off the toolbox VM (keeps the disk)
	@pid=$$(cat $(TB_PID) 2>/dev/null); \
	if [ -n "$$pid" ] && kill -0 $$pid 2>/dev/null; then \
		echo "$(call ann,Yellow) Powering off $(TB_NAME). The disk and its tools stay put"; \
		kill $$pid; \
		for i in $$(seq 50); do kill -0 $$pid 2>/dev/null || break; sleep 0.1; done; \
		kill -0 $$pid 2>/dev/null && kill -9 $$pid; \
	else \
		echo "$(call ann,Yellow) $(TB_NAME) wasn't running"; \
	fi
	@rm -f $(TB_PID) $(TB_MON)

toolbox-destroy: toolbox-stop ## Stop the toolbox and delete its disk (keeps the base image)
	@echo "$(call ann,Red) Shredding the toolbox disk and seed. The base image lives, 350 MiB is a long walk back"
	@rm -f $(TB_DISK) $(TB_SEED) $(TB_SSHCFG) $(TB_DIR)/known_hosts $(TB_DIR)/seed/* 2>/dev/null; rmdir $(TB_DIR)/seed 2>/dev/null || true
	@echo "$(call ann,Green) Gone. make toolbox rebuilds it from the base image"

_tb-store:
	@command -v $(QEMU) >/dev/null || { echo "$(call ann,Red) No $(QEMU). dnf install qemu-system-x86"; exit 1; }
	@[ -n "$(TB_MKISO)" ] || { echo "$(call ann,Red) Nothing here can burn the cloud-init ISO. dnf install xorriso"; exit 1; }
	@mkdir -p $(TB_DIR) 2>/dev/null || true
	@[ -w "$(TB_DIR)" ] || { echo "$(call ann,Red) $(TB_DIR) won't have me. Point TB_DIR somewhere you own"; exit 1; }
	@r=$$(readlink -f $(TB_DIR)); \
	if [ "$${r#$(HOME)/}" != "$$r" ]; then \
		echo "$(call ann,Red) $(TB_DIR) lands in your home ($$r). A VM against your quota is a bad time. Not on my watch"; \
		exit 1; \
	fi

_tb-wait:
	@echo "$(call ann,Blue) Knocking on the toolbox SSH. Debian boots, then apt drags the tools in"
	@for i in $$(seq 1 300); do \
		if $(TB_SSH) true 2>/dev/null; then \
			echo "$(call ann,Blue) In. Letting cloud-init finish apt (first boot only, grab that coffee)"; \
			$(TB_SSH) 'cloud-init status --wait >/dev/null 2>&1 || true'; \
			exit 0; \
		fi; \
		$(TB_RUNNING) || { echo "$(call ann,Red) qemu died during boot. See $(TB_LOG)"; exit 1; }; \
		sleep 2; \
	done; \
	echo "$(call ann,Red) No SSH after 10 min. Boot log: $(TB_LOG)"; \
	exit 1

$(TB_KEY):
	@mkdir -p $(TB_DIR)
	@echo "$(call ann,Cyan) Minting a throwaway SSH key for the toolbox"
	@ssh-keygen -t ed25519 -N '' -C snowcrash-toolbox -f $(TB_KEY) >/dev/null

$(TB_SSHCFG): $(TB_KEY)
	@printf 'Host toolbox\n  HostName 127.0.0.1\n  User %s\n  Port %s\n  IdentityFile %s\n  IdentitiesOnly yes\n  StrictHostKeyChecking no\n  UserKnownHostsFile %s/known_hosts\n  ConnectTimeout 4\n  LogLevel ERROR\n' \
		"$(TB_USER)" "$(TB_SSH_PORT)" "$(TB_KEY)" "$(TB_DIR)" > $@

$(TB_BASE):
	@mkdir -p $(TB_DIR)
	@echo "$(call ann,Cyan) Pulling $(DEBIAN_IMG), ~350 MiB. This is the slow part, go stretch"
	@curl -fL --progress-bar -o $(TB_BASE).part $(DEBIAN_URL)
	@echo "$(call ann,Blue) Checking the SHA512. Trusting the internet is a personality flaw"
	@expected=$$(curl -fsSL $(DEBIAN_SUMS) | awk '$$2 == "$(DEBIAN_IMG)" { print $$1 }'); \
	actual=$$(sha512sum $(TB_BASE).part | cut -d' ' -f1); \
	if [ -z "$$expected" ] || [ "$$expected" != "$$actual" ]; then \
		rm -f $(TB_BASE).part; \
		echo "$(call ann,Red) Checksum mismatch. Something died in transit. I'm not booting that"; \
		exit 1; \
	fi
	@mv $(TB_BASE).part $(TB_BASE)
	@echo "$(call ann,Green) Down and verified. Debian, sealed for freshness"

$(TB_DISK): $(TB_BASE)
	@[ "$$($(TB_RUNNING) && echo up)" != up ] || { echo "$(call ann,Red) Toolbox is running. Stop it before recarving its disk"; exit 1; }
	@echo "$(call ann,Cyan) Carving a $(TB_DISK_SZ) overlay on the base image. The original stays clean"
	@qemu-img create -q -f qcow2 -F qcow2 -b $(TB_BASE) $(TB_DISK) $(TB_DISK_SZ)

$(TB_SEED): $(TB_TMPL)/user-data.yaml.in $(TB_KEY)
	@mkdir -p $(TB_DIR)/seed
	@echo "$(call ann,Cyan) Writing the cloud-init seed (the tool list lives here)"
	@$(TB_RENDER) -e "s|@SSH_PUBKEY@|$$(cat $(TB_KEY).pub)|g" \
		$< > $(TB_DIR)/seed/user-data
	@printf 'instance-id: %s\nlocal-hostname: snowcrash-toolbox\n' "$(TB_NAME)" > $(TB_DIR)/seed/meta-data
	@$(TB_MKISO) -quiet -output $@ -volid CIDATA -joliet -rock \
		$(TB_DIR)/seed/user-data $(TB_DIR)/seed/meta-data >/dev/null

$(TB_KEY).pub: $(TB_KEY)
