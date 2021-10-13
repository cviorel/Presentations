variable vsphere_server {
  description = "vSphere server for the environment - EXAMPLE: vcenter01.vsphere.local"
}

variable vsphere_user {
  description = "vSphere server for the environment - EXAMPLE: administrator@vsphere.local"

}
variable vsphere_password {
  description = "vSphere server password for the environment"
}

variable windows_admin_user {
  description = "Windows Administrator for Windows VMs"
}

variable "datacenter" {
  description = "Datacenter name"
}
variable "cluster" {
  description = "Cluster name"
}

variable "datastore" {
  description = "Datastore name"
}

variable "pool" {
  description = "Resource pool"
}

variable "network" {
  description = "Network name"
}

variable "template_windows_gui" {
  description = "Template for deploying Windows withe a GUI"
}

variable "template_windows_core" {
  description = "Template for deploying Windows Core"
}

variable "template_linux" {
  description = "Template for deploying linux"
}

variable windows_admin_password {
  description = "Windows Administrator password for Windows VMs"
}

variable linux_admin_user {
  description = "Linux Administrator for Linux VMs"
}

variable linux_admin_password {
  description = "Linux Administrator password for Linux VMs"
}

variable vm_gateway {
  description = "Gateway"
  type        = string
}

variable vm_dns_servers {
  description = "DNS Servers"
  type        = list(string)
}

variable "vm_linux_name" {
  type    = list
  default = ["Ubuntu01", "Ubuntu02", "Ubuntu03", "Ubuntu04"]
}

variable "vm_windows_gui_name" {
  type    = list
  default = ["WinGui01"]
}

variable "vm_windows_core_name" {
  type    = list
  default = ["WinCore01", "WinCore02", "WinCore03"]
}

variable "vm_mapping" { #variable type map
  type = map(string)
  default = {
    WinCore01 = "192.168.1.81"
    WinCore02 = "192.168.1.82"
    WinCore03 = "192.168.1.83"
    WinGui01 = "192.168.1.84"
    WinGui02 = "192.168.1.85"
    WinGui03 = "192.168.1.86"
    WinGui04 = "192.168.1.87"
    Ubuntu01 = "192.168.1.88"
    Ubuntu02 = "192.168.1.89"
    Ubuntu03 = "192.168.1.91"
    Ubuntu04 = "192.168.1.92"
  }
}
