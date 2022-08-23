# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 2.2.7"

logger = Vagrant::UI::Colored.new

required_plugins = %w( rb-readline vagrant-ghost vagrant-vbguest vagrant-persistent-storage vagrant-git vagrant-docker-compose )
missing_plugins = []
required_plugins.each do |plugin|
	missing_plugins.push(plugin) unless Vagrant.has_plugin? plugin
end
if ! missing_plugins.empty?
	install_these = missing_plugins.join(' ')
	logger.warn "Required following plugins: #{install_these}."
	if system "vagrant plugin install #{install_these}"
		exec "vagrant #{ARGV.join(' ')}"
		Kernel.exit!(0)
	else
		logger.warn "Error install plugins, please install these plugins then restart vagrant:"
		logger.warn "   #{install_these}"
		Kernel.exit!(0)
	end
end

require "getoptlong"
require "readline"
require "./lib/functions.rb"
require 'open3'
require 'fileutils'

# Check various settings only on vargrant up/reload/provision
if ARGV.index('up') or ARGV.index('reload') or ARGV.index('provision')

	opts = GetoptLong.new(
		[ '--provision-script', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--provision-site', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--git-username', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--git-email', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--provision', GetoptLong::OPTIONAL_ARGUMENT ],
		[ '--no-provision', GetoptLong::OPTIONAL_ARGUMENT ],
	)

	Dir.mkdir("./bitbucket") unless Dir.exist?("./bitbucket")
	Dir.mkdir("./github") unless Dir.exist?("./github")
	FileUtils.mkpath(".vagrant/hdd") unless Dir.exist?(".vagrant/hdd")

end


# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure("2") do |config|

	config.vbguest.auto_update     = true
	config.vbguest.auto_reboot     = true
	config.vbguest.allow_downgrade = true

	# Configure the virtual box VM during boot
	# @see https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm
	config.vm.provider "virtualbox" do |vb|

		# Display the VirtualBox GUI when booting the machine
		# vb.gui = true

		# Give VM access to all cpu cores on the host
		# vb.cpus = detect_max_cpus 2, 0.5

		# Allow the VM to utilize up to 75% of the host system memory
		vb.memory = detect_max_mem 4096, 0.75

		# @ref https://www.virtualbox.org/manual/ch08.html#vboxmanage-modifyvm

		# Only allow the VM to eat up-to 50% of the host system cpu
		vb.customize ["modifyvm", :id, "--cpuexecutioncap", "50"]

		# Instruct Vagrant to utilize all the cpu cores we've provided above
		# Without this only 1 core will be used
		vb.customize ["modifyvm", :id, "--ioapic", "on"]

		# Plug in the virtual network adapter as if it were a real cat-5 cable
		# plugged into a real network card. This corrects an error presented with
		# Ubuntu 16 where boot hangs on: "A start job is running for Raise network interfaces"
		# This error occurs because Ubuntu tries to raise all the network interfaces,
		# but the 'cable' isn't connected, so it waits until the timeout.
		# Note, this is the same as selecting 'Cable Connect' for the network adapter
		# in the VirtualBox app settings for this box.
		# https://github.com/hashicorp/vagrant/issues/8056#issuecomment-267600935
		vb.customize ["modifyvm", :id, "--cableconnected1", "on"]

		# Turn off un-use devices
		vb.customize ["modifyvm", :id, "--usb", "off"]
		vb.customize ["modifyvm", :id, "--usbehci", "off"]
		vb.customize ["modifyvm", :id, "--usbxhci", "off"]
		vb.customize ["modifyvm", :id, "--accelerate3d", "off"]
		vb.customize ["modifyvm", :id, "--accelerate2dvideo", "off"]
		vb.customize ["modifyvm", :id, "--audio", "none"]
		vb.customize ["modifyvm", :id, "--vrde", "off"]

		# Ubuntu 18.04 required this port to open for console log, otherwise it will failed boot
		vb.customize ["modifyvm", :id, "--uartmode1", "file", File.join(Dir.pwd, ".vagrant/console.log") ]

	end

	# Global provision that run before all individual instance provision scripts
	# config.vm.provision ...

	# config for pmcdev.local
	config.vm.define "pmcdev.local", primary: true, autostart: true do |web|

		web.vm.box              = "ubuntu/bionic64"
		web.vm.box_check_update = true

		# IMPORTANT: ubuntu/bionic64 relady used /dev/sda & /dev/sdb
		web.persistent_storage.diskdevice = '/dev/sdc'
		web.persistent_storage.enabled    = true
		web.persistent_storage.filesystem = "ext4"
		web.persistent_storage.format     = true;
		web.persistent_storage.location   = ".vagrant/hdd/docker.vdi"
		web.persistent_storage.mount      = true;
		web.persistent_storage.mountname  = "docker"
		web.persistent_storage.mountpoint = "/var/lib/docker"
		web.persistent_storage.partition  = true
		web.persistent_storage.size       = 500 * 1024
		web.persistent_storage.use_lvm    = false

		# the root folder
		# /. -> /vagrant is already auto mapped by vagrant
		web.vm.synced_folder "./", "/pmc-dev", owner: "vagrant", group: "vagrant", mount_options: ["dmode=755", "fmode=644"]

		# https://github.com/leighmcculloch/vagrant-docker-compose
		web.vm.provision :docker
        web.vm.provision :docker_compose,
            yml: "/pmc-dev/docker-compose.yml",
            project_name: "pmc-dev",
            run: "always",
            command_options: {
                up: "-d wp"
            }

	end
end
