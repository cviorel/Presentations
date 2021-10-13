output "virtual_machines_linux" {
  value = {
    for instance in vsphere_virtual_machine.vm_linux :
    instance.id => concat(instance.*.name, instance.*.default_ip_address)
  }
}

output "virtual_machines_windows_core" {
  value = {
    for instance in vsphere_virtual_machine.vm_windows_core :
    instance.id => concat(instance.*.name, instance.*.default_ip_address)
  }
}

output "virtual_machines_windows_gui" {
  value = {
    for instance in vsphere_virtual_machine.vm_windows_gui :
    instance.id => concat(instance.*.name, instance.*.default_ip_address)
  }
}
