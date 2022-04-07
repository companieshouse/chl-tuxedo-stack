mounts:
 - [ "ipo-file-svm-lif-be1.internal.ch:chd_image", "/home/scud/downloadchd/email", "nfs", "hard", "bg" ]
 - [ "ipo-file-svm-lif-be1.internal.ch:chcc_email", "/home/scud/downloadceu/email", "nfs", "hard", "bg" ]
 - [ "ipo-file-svm-lif-be1.internal.ch:wck_image", "/home/scud/downloadwck/email", "nfs", "hard", "bg" ]
 - [ "ipo-file-svm-lif-be1.internal.ch:chcc_post", "/home/scud/downloadceu/post", "nfs", "hard", "bg" ]

runcmd:
  - hostnamectl set-hostname ${instance_hostname}
  %{~ for block_device in lvm_block_devices ~}
  %{ if block_device.filesystem_resize_tool != "" }
  - pvresize ${block_device.lvm_physical_volume_device_node}
  - lvresize -l +100%FREE ${block_device.lvm_logical_volume_device_node}
  - ${block_device.filesystem_resize_tool} ${block_device.lvm_logical_volume_device_node}
  %{ endif }
  %{~ endfor ~}
