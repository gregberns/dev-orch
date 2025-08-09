**Multipass has excellent snapshot and cloning capabilities** that work exactly like Docker layers - you can create a "golden image" setup once, then instantly spin up copies with different names.

Here are the **three main approaches** for reusable VM templates:

## **1. Snapshots (Best for Template Workflow)**

**Create your perfect setup once, then clone it infinitely:**

```bash
# 1. Create and configure your "template" VM
multipass launch --name template-vm --cpus 2 --memory 4G --cloud-init setup.yaml

# 2. Set up everything you want (Podman, databases, tools, etc.)
multipass shell template-vm
# ... install and configure everything ...
# exit when done

# 3. Stop VM and take a snapshot
multipass stop template-vm
multipass snapshot template-vm --name golden-image

# 4. Now you can instantly create new VMs from this snapshot
multipass launch --name project-a --snapshot template-vm.golden-image
multipass launch --name project-b --snapshot template-vm.golden-image
multipass launch --name project-c --snapshot template-vm.golden-image
```

## **2. VM Cloning (Simplest)**

**Clone entire VMs with all their state:**

```bash
# 1. Create and set up your template VM
multipass launch --name template-vm --cpus 2 --memory 4G
# ... configure everything ...

# 2. Stop the VM
multipass stop template-vm

# 3. Clone it with new names (available since Multipass 1.15.0)
multipass clone template-vm --name project-a
multipass clone template-vm --name project-b
multipass clone template-vm --name project-c

# 4. Start the clones
multipass start project-a project-b project-c
```

## **3. Custom Images with Packer (Advanced)**

**Create reusable images that can be distributed:**

```bash
# Build custom image once
packer build template.json

# Launch multiple VMs from the same custom image
multipass launch file:///path/to/custom-image.qcow2 --name vm-1
multipass launch file:///path/to/custom-image.qcow2 --name vm-2
```

**Note**: Custom images only work on Linux hosts currently.

## **Complete Example Workflow**

Here's a practical script for your PostgreSQL + Podman template:

```bash
#!/bin/bash

# Create the golden template (run once)
create_template() {
    echo "Creating template VM..."

    # Create cloud-init config
    cat > template-config.yaml << EOF
#cloud-config
package_update: true
packages:
  - podman
  - podman-compose
runcmd:
  - systemctl --user enable podman.socket --now
  - loginctl enable-linger ubuntu
write_files:
  - path: /home/ubuntu/postgres-compose.yml
    content: |
      services:
        postgres:
          image: postgres:15
          environment:
            POSTGRES_PASSWORD: mysecret
          volumes:
            - pgdata:/var/lib/postgresql/data
          ports:
            - "5432:5432"
      volumes:
        pgdata:
EOF

    # Launch and configure template
    multipass launch --name template-vm --cpus 2 --memory 4G --cloud-init template-config.yaml
    multipass exec template-vm -- cloud-init status --wait

    # Take snapshot
    multipass stop template-vm
    multipass snapshot template-vm --name golden-podman

    echo "Template ready! Snapshot: template-vm.golden-podman"
}

# Create new project VMs from template (run multiple times)
create_project_vm() {
    PROJECT_NAME="$1"
    HOST_DIR="$HOME/multipass-vms/$PROJECT_NAME"

    echo "Creating VM: $PROJECT_NAME"

    # Launch from snapshot
    multipass launch --name "$PROJECT_NAME" --snapshot template-vm.golden-podman

    # Set up host directory and mount
    mkdir -p "$HOST_DIR"
    multipass mount "$PROJECT_NAME:/home/ubuntu/workspace" "$HOST_DIR"

    # Start PostgreSQL
    multipass exec "$PROJECT_NAME" -- podman-compose -f postgres-compose.yml up -d

    VM_IP=$(multipass info "$PROJECT_NAME" | grep IPv4 | awk '{print $2}')
    echo "Project VM '$PROJECT_NAME' ready!"
    echo "PostgreSQL: psql -h $VM_IP -U postgres"
    echo "Workspace: $HOST_DIR"
}

# Usage
case "$1" in
    template)
        create_template
        ;;
    create)
        create_project_vm "$2"
        ;;
    *)
        echo "Usage: $0 {template|create PROJECT_NAME}"
        echo "  template: Create the golden template once"
        echo "  create:   Create new project VM from template"
        ;;
esac
```

**Usage:**
```bash
# Create template once
./vm-template.sh template

# Create project VMs instantly
./vm-template.sh create project-alpha
./vm-template.sh create project-beta
./vm-template.sh create client-demo
```

## **Key Benefits**

✅ **Instant startup** - VMs launch in seconds from snapshots
✅ **Consistent environment** - Every VM has identical base setup
✅ **Resource efficient** - Snapshots use copy-on-write (like Docker layers)
✅ **Easy management** - Each VM gets its own name and host directory
✅ **Rollback capability** - Can restore VMs to snapshot state

This gives you the **best of both worlds**: Docker-like convenience for VM management with true isolation and the ability to run full containerized stacks inside each VM.

[1] https://documentation.ubuntu.com/multipass/en/latest/reference/command-line-interface/snapshot/
[2] https://documentation.ubuntu.com/multipass/en/latest/how-to-guides/customise-multipass/build-multipass-images-with-packer/
[3] https://www.reddit.com/r/kvm/comments/z31ltq/reuse_windows_vmware_template_in_kvm_virtio/
[4] https://canonical.com/multipass/install
[5] https://github.com/taypo/multipass-images
[6] https://github.com/canonical/multipass/issues/1512
[7] https://dev.to/adityapratapbh1/a-comprehensive-guide-to-multipass-simplifying-virtual-machine-management-b0c
[8] https://faun.pub/a-comprehensive-guide-to-multipass-simplifying-virtual-machine-management-765cafba8c9b
[9] https://github.com/canonical/multipass/issues/1335
[10] https://discourse.ubuntu.com/t/can-i-backup-the-multipass-image/32533
[11] https://github.com/canonical/multipass/issues/307
[12] https://documentation.ubuntu.com/multipass/
[13] https://github.com/canonical/multipass/blob/main/README.md
[14] https://discourse.ubuntu.com/t/is-there-a-way-to-utilize-a-custom-image-like-ubuntu-23-10-as-a-guest-vm-in-multipass/40232
[15] https://ryan-schachte.com/blog/homelab_observability/
[16] https://canonical.com/multipass
[17] https://www.r-studio.com/Unformat_Help/multipass-imaging.html
[18] https://www.greghilston.com/post/proxmox-template/
[19] https://jnsgr.uk/2024/06/desktop-vms-lxd-multipass/
[20] https://stackoverflow.com/questions/72222724/how-can-i-use-cloud-init-to-set-up-a-vm-with-multipass-that-includes-zsh
[21] https://discourse.ubuntu.com/t/multipass-restore-command/39844
[22] https://discourse.ubuntu.com/t/multipass-clone-command/47779
[23] https://documentation.ubuntu.com/multipass/en/latest/explanation/snapshot/
[24] https://pandac.in/blogs/multipass/
[25] https://github.com/canonical/multipass/issues/3929
[26] https://discourse.ubuntu.com/t/how-to-build-multipass-images-with-packer/12361
[27] https://www.youtube.com/watch?v=c5soWjCVBpY
[28] https://aws.plainenglish.io/a-step-by-step-guide-to-restoring-an-ec2-instance-from-a-snapshot-58922be4b3b6
[29] https://github.com/canonical/multipass/issues/1029
[30] https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_RestoreFromMultiAZDBClusterSnapshot.html
[31] https://github.com/canonical/multipass/issues/726
[32] https://technekey.com/creating-multiple-virtual-machines-fast-using-multipass/
[33] https://github.com/canonical/multipass
[34] https://learn.arm.com/install-guides/multipass/
