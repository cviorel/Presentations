provider "vsphere" {
  user           = var.vsphere_user
  password       = var.vsphere_password
  vsphere_server = var.vsphere_server

  # If you use self-signed certificates
  allow_unverified_ssl = true
}

# Create a folder
resource "vsphere_folder" "terraform_folder" {
  datacenter_id = data.vsphere_datacenter.dc.id
  type          = "vm"
  path          = "TerraformLab"
}

# Windows Core VM from Template
resource "vsphere_virtual_machine" "vm_windows_core" {
  for_each = toset(var.vm_windows_core_name)

  name             = "tf-${lower(each.key)}"
  folder           = vsphere_folder.terraform_folder.path
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  firmware                = "bios"
  efi_secure_boot_enabled = "false"

  num_cpus                   = 2
  memory                     = 4096
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 30

  guest_id = data.vsphere_virtual_machine.template_windows_core.guest_id

  scsi_type = data.vsphere_virtual_machine.template_windows_core.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template_windows_core.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template_windows_core.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template_windows_core.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template_windows_core.id

    customize {
      windows_options {
        computer_name = "tf-${lower(each.key)}"
        workgroup     = "WORKGROUP"
        admin_password = var.windows_admin_password
        run_once_command_list = [
          "Start-Service WinRM",
          "netsh advfirewall firewall add rule name=\"Windows Remote Management\" dir=in action=allow protocol=TCP localport=5985",
          "winrm quickconfig -force",
          "winrm set winrm/config @{MaxEnvelopeSizekb=\"100000\"}",
          "winrm set winrm/config/Service @{AllowUnencrypted=\"true\"}",
          "winrm set winrm/config/Service/Auth @{Basic=\"true\"}",
          "Stop-Service WinRM",
          "Start-Service WinRM"
        ]
      }

      network_interface {
        ipv4_address    = lookup(var.vm_mapping, each.value)
        ipv4_netmask    = 24
        dns_server_list = var.vm_dns_servers
      }

      ipv4_gateway = var.vm_gateway
    }
  }

  provisioner "file" {
    source      = "${path.module}\\scripts\\Post-Deploy-Windows.ps1"
    destination = "C:\\Post-Deploy-Windows.ps1"
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "winrm"
      user     = var.windows_admin_user
      password = var.windows_admin_password
      insecure = true
    }
  }
  provisioner "remote-exec" {
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "winrm"
      user     = var.windows_admin_user
      password = var.windows_admin_password
    }
    inline = [
      "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force",
      "powershell.exe -ExecutionPolicy Unrestricted -File C:\\Post-Deploy-Windows.ps1"
    ]
  }
}

# Windows GUI VM from Template
resource "vsphere_virtual_machine" "vm_windows_gui" {
  for_each = toset(var.vm_windows_gui_name)

  name             = "tf-${lower(each.key)}"
  folder           = vsphere_folder.terraform_folder.path
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  firmware                = "bios"
  efi_secure_boot_enabled = "false"

  num_cpus                   = 2
  memory                     = 6144
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 30

  guest_id = data.vsphere_virtual_machine.template_windows_gui.guest_id

  scsi_type = data.vsphere_virtual_machine.template_windows_gui.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template_windows_gui.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template_windows_gui.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template_windows_gui.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template_windows_gui.id

    customize {
      windows_options {
        computer_name = "TF-${upper(each.key)}"
        workgroup     = "WORKGROUP"
        admin_password = var.windows_admin_password
        run_once_command_list = [
          "Start-Service WinRM",
          "netsh advfirewall firewall add rule name=\"Windows Remote Management\" dir=in action=allow protocol=TCP localport=5985",
          "winrm quickconfig -force",
          "winrm set winrm/config @{MaxEnvelopeSizekb=\"100000\"}",
          "winrm set winrm/config/Service @{AllowUnencrypted=\"true\"}",
          "winrm set winrm/config/Service/Auth @{Basic=\"true\"}",
          "Stop-Service WinRM",
          "Start-Service WinRM"
        ]
      }

      network_interface {
        ipv4_address    = lookup(var.vm_mapping, each.value)
        ipv4_netmask    = 24
        dns_server_list = var.vm_dns_servers
      }

      ipv4_gateway = var.vm_gateway
    }
  }

  provisioner "file" {
    source      = "${path.module}\\scripts\\Post-Deploy-Windows.ps1"
    destination = "C:\\Post-Deploy-Windows.ps1"
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "winrm"
      user     = var.windows_admin_user
      password = var.windows_admin_password
      insecure = true
    }
  }
  provisioner "remote-exec" {
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "winrm"
      user     = var.windows_admin_user
      password = var.windows_admin_password
    }
    inline = [
      "powershell.exe Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Force",
      "powershell.exe -ExecutionPolicy Unrestricted -File C:\\Post-Deploy-Windows.ps1"
    ]
  }
}

# Linux VM from Template
resource "vsphere_virtual_machine" "vm_linux" {
  for_each = toset(var.vm_linux_name)

  name             = "tf-${lower(each.key)}"
  folder           = vsphere_folder.terraform_folder.path
  resource_pool_id = data.vsphere_compute_cluster.cluster.resource_pool_id
  datastore_id     = data.vsphere_datastore.datastore.id

  firmware                = "bios"
  efi_secure_boot_enabled = "false"

  num_cpus                   = 2
  memory                     = 2048
  wait_for_guest_net_timeout = 0
  wait_for_guest_ip_timeout = 30

  guest_id = data.vsphere_virtual_machine.template_linux.guest_id

  scsi_type = data.vsphere_virtual_machine.template_linux.scsi_type

  network_interface {
    network_id = data.vsphere_network.network.id
    adapter_type = "vmxnet3"
  }

  disk {
    label            = "disk0"
    size             = data.vsphere_virtual_machine.template_linux.disks.0.size
    eagerly_scrub    = data.vsphere_virtual_machine.template_linux.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.template_linux.disks.0.thin_provisioned
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template_linux.id

    customize {
      linux_options {
        host_name = "tf-${lower(each.key)}"
        domain    = "lab.local"
      }

      network_interface {
        ipv4_address = lookup(var.vm_mapping, each.value)
        ipv4_netmask = 24
      }

      ipv4_gateway    = var.vm_gateway
      dns_server_list = var.vm_dns_servers

    }
  }

  provisioner "file" {
    source      = "${path.module}\\scripts\\Post-Deploy-Linux.sh"
    destination = "/tmp/Post-Deploy-Linux.sh"
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "ssh"
      user     = var.linux_admin_user
      password = var.linux_admin_password
    }
  }
  provisioner "remote-exec" {
    connection {
      host     = lookup(var.vm_mapping, each.value)
      type     = "ssh"
      user     = var.linux_admin_user
      password = var.linux_admin_password
    }
    inline = [
      "chmod +x /tmp/Post-Deploy-Linux.sh",
      "/tmp/Post-Deploy-Linux.sh",
    ]
  }

}
