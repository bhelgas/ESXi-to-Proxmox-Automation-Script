#!/bin/bash
# VM Configuration
VM_ID="1"
VM_NAME="Name of virtual machine"
VM_RAM="20480"
VM_CORES="8" 
DISK_SIZE="100G"
ENABLE_TPM=true

TEMP_DIR="/path/to/temporary-vmdk-files/"
QCOW2_FILE="nameofcqow2file.qcow2"
VMDK_FILE="nameofvmdkfile.vmdk"

START_TIME=$(date +%s)


# Logging function
log_message() {
    local msg="$1"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" >> /mnt/pve/DISKNAME/logs/backup.log
}
# Create temporary directory for saving files
log_message "Creating temporary save location in $TEMP_DIR"
mkdir -p $TEMP_DIR || {
    log_message "Failed to create $TEMP_DIR";
    exit 1;
}
log_message "Directory \"$TEMP_DIR\" created successfully!"

# Fetch latest VMDK file from remote server
log_message "Fetching latest VMDK file from remote server.."
sshpass -p "password (THis is an insecure solution) " scp "root"@"x.x.x.x":"/path/to/vmdk-file/$VMDK_FILE" "$TEMP_DIR" || {
    log_message "Failed to fetch VMDK file";
    exit 1;
}
log_message "File copied to $TEMP_DIR"

# Convert VMDK file to QCOW2
log_message "Converting file.."
qemu-img convert -f raw -O qcow2 "$TEMP_DIR/$VMDK_FILE" "$TEMP_DIR/$QCOW2_FILE" || {
    log_message "Could not convert file";
    exit 1;
}
log_message "File converted and is located in \"$TEMP_DIR/$QCOW2_FILE\""

# Stop existing VM if running
log_message "Stopping previous backup server"
qm stop $VM_ID || {
    log_message "Failed to stop VM ($VM_ID)";
    exit 1;
}
log_message "Virtual machine ($VM_ID) stopped"
# Destroy old VM to remove any old configuration and disk files

log_message "Removing old disk- and configuration files"
qm destroy $VM_ID || {
    log_message "Failed to remove old disk files";
    exit 1;
}
log_message "Files removed"

# Create a new virtual machine with the specified configuration
log_message "Creating a new virtual machine with ID $VM_ID and name \"$VM_NAME\""
qm create $VM_ID --name $VM_NAME --memory $VM_RAM --cores $VM_CORES --net0 virtio --scsihw virtio-scsi-single --bios ovmf || {
    log_message "Failed to create VM $VM_ID";
    exit 1;
}
log_message "Virtual machine \"$VM_NAME\" successfully created"

# Add EFI disk to the VM
log_message "Adding EFI to the virtual machine ($VM_ID)"
qm set $VM_ID --efidisk0 vm-disks:0,format=raw,efitype=4m,pre-enrolled-keys=1 || {
    log_message "Could not add EFI disk";
    exit 1;
}
log_message "EFI Disk added to virtual machine as vm-$VM_ID-disk-0.raw"

# Add TPM if enabled
if [ "$ENABLE_TPM" = true ]; then
    # Add TPM to the VM
    log_message "Adding TPM to the virtual machine ($VM_ID)"
    qm set $VM_ID --tpmstate0 vm-disks:1,version=v2.0  || {
        log_message "Could not add TPM disk";
        exit 1;
    }
    log_message "TPM Disk added to virtual machine as vm-$VM_ID-disk-1.raw"
else 
 log_message "TPM configuration skipped for virtual machine ($VM_ID)"
fi

# Import disk to Proxmox VM storage
log_message "Importing disk files to vm-disks"
qm importdisk $VM_ID "$TEMP_DIR/$QCOW2_FILE" vm-disks --format raw || {
    log_message "Could not import disk file to vm-disks/$QCOW2_FILE";
    exit 1;
}
log_message "Disk successfully imported to vm-disks as vm-$VM_ID-disk-2.raw"

# Attach disk to the VM
log_message "Attaching disk to virtual machine ($VM_ID)"
qm set $VM_ID --ide0 vm-disks:$VM_ID/vm-$VM_ID-disk-2.raw,size=$DISK_SIZE || {
    log_message "Could not attach disk to VM";
    exit 1;
}
log_message "Disk successfully attached to virtual machine ($VM_ID)"

# Set the primary boot disk
log_message "Setting \"ide0\" as primary bootdisk"
qm set $VM_ID --bootdisk ide0 --boot order=ide0,net0 || {
    log_message "Could not set \"ide0\" as primary bootdisk";
    exit 1;
}
log_message "\"ide0\" has been set as the primary bootdisk successfully on virtual machine ($VM_ID)"

# Start the VM
log_message "Starting VM ($VM_ID, $VM_NAME)"
qm start $VM_ID || {
    log_message "Failed to start VM $VM_ID";
    exit 1;
}
log_message "Virtual machine ($VM_ID, $VM_NAME) has started successfully"

# Clean up temporary files
log_message "Cleaning up temporary files"
rm -rf $TEMP_DIR || {
    log_message "Failed to remove temporary directory: $TEMP_DIR";
    exit 1;
}
log_message "Cleaned directory."

END_TIME=$(date +%s)

# Calculate duration
DURATION=$((END_TIME - START_TIME))
HOURS=$((DURATION / 3600))
MINUTES=$(((DURATION % 3600) / 60))
SECONDS=$((DURATION % 60))



# Display the current time of backup completion
echo "Backup finished at $(date '+%I:%M %p on %A, %B %d, %Y'). \n Time taken: ${HOURS} hours, ${MINUTES} minutes, ${SECONDS} seconds "
