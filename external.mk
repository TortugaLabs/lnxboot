RUN_QEMU_MEM = 1024
RUN_QEMU_CPUS = 1
RUN_QEMU_OSINFO = linux2022
RUN_QEMU_CONSOLE = --autoconsole graphical
RUN_QEMU_HYPERVISOR = kvm

$(O)/images/qemu.img:
	$(BR2_EXTERNAL_LNXBOOT_PATH)/board/lnxboot/mkimg.sh $@

img: $(O)/images/qemu.img

run-qemu: $(O)/images/qemu.img
	virt-install \
        --name brtest \
        --memory $(RUN_QEMU_MEM) \
        --vcpus $(RUN_QEMU_CPUS) \
        --clock offset=utc \
        --disk $< \
        --osinfo $(RUN_QEMU_OSINFO) \
        $(RUN_QEMU_CONSOLE) \
        --virt-type $(RUN_QEMU_HYPERVISOR) \
        --watchdog default \
        --rng /dev/urandom \
        --import --transient \
        --boot uefi

lnxboot-update:
#~ 	make savedefconfig  # This doesn't work
#~ 	 BR2_DEFCONFIG=$(BR2_EXTERNAL_LNXBOOT_PATH)/configs/lnxboot_defconfig
	make -C $(O) linux-update-defconfig BR2_LINUX_KERNEL_CUSTOM_CONFIG_FILE=linux.config
