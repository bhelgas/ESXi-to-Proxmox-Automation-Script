# VMDK to QCOW2 Conversion Script
## ESXi to Proxmox migration

This script automates the process of converting a VMDK file from ESXi to QCOW2 format, making it ready for use in Proxmox. It handles backup, VM creation, disk import, and more to facilitate seamless migration from ESXi to Proxmox.

## Requirements

- **Proxmox VE**: The script assumes you're using Proxmox Virtual Environment to manage your VMs.
- **SSH**: For remote file fetching (you must have SSH access to the remote server hosting the VMDK file).
- **qemu-img**: The `qemu-img` tool is required to convert VMDK files to QCOW2 format.

## Usage

### Script Configuration

- **VM_ID**: The ID of the Proxmox virtual machine.
- **VM_NAME**: The name of the virtual machine to be created in Proxmox.
- **VM_RAM**: The amount of RAM to assign to the virtual machine (in MB).
- **VM_CORES**: The number of CPU cores to assign to the virtual machine.
- **DISK_SIZE**: The size of the virtual disk (e.g., `100G`).
- **ENABLE_TPM**: Set to `true` to enable TPM for the VM, or `false` to skip it.
- **TEMP_DIR**: Path to the temporary directory where the VMDK file will be stored temporarily during the conversion.
- **VMDK_FILE**: The VMDK file to be fetched and converted.
- **QCOW2_FILE**: The output QCOW2 file name.

### Running the Script

1. Make sure your Proxmox environment is properly configured.
2. Place the script on your Proxmox host.
3. Edit the script and adjust the variables according to your environment (VM ID, VM name, VMDK file path, etc.).
4. Execute the script as root:
    ```bash
    sudo ./vmdk_to_qcow2.sh
    ```

### What It Does

1. **Fetches the VMDK file**: The script retrieves the latest VMDK file from a remote server using SSH and SCP.
2. **Converts VMDK to QCOW2**: It uses `qemu-img` to convert the VMDK file to QCOW2 format, which is optimized for Proxmox.
3. **VM Management**:
   - Stops any running VM with the specified ID.
   - Destroys the existing VM configuration to remove old disk and configuration files.
   - Creates a new virtual machine with the provided configuration (RAM, cores, etc.).
   - Adds EFI and TPM if enabled.
4. **Disk Import**: Imports the converted QCOW2 disk file into Proxmox storage and attaches it to the new virtual machine.
5. **Boot Configuration**: Sets the primary boot disk to the imported disk and configures the boot order.
6. **Starts the VM**: The virtual machine is started, now using the converted disk.
7. **Cleans up**: Removes temporary files created during the process.

### Logging

The script generates logs at `/mnt/pve/vm-disks/logs/backup.log` to track each step of the process. Logs include timestamps and the status of each operation.

### Example

```bash
# Set the appropriate values for your system:
VM_ID="101"
VM_NAME="example-vm"
VM_RAM="8192"  # 8 GB RAM
VM_CORES="4"
DISK_SIZE="50G"
ENABLE_TPM=true
TEMP_DIR="/tmp/vmdk-temp/"
VMDK_FILE="example-vmdk.vmdk"
QCOW2_FILE="example.qcow2"
```

# Run the script
sudo ./script.sh


# Notes
Insecure SSH password: The script currently uses an insecure method for fetching the VMDK file (`sshpass` with password). Consider replacing this with a more secure solution (e.g., SSH keys) for production use.
Customization: You can modify the script to suit your needs, such as adding more VM configurations, changing directories, or adjusting the disk format.

#License
This script is provided under the MIT License.

Feel free to reach out with any questions or suggestions.
