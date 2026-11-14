#!/bin/bash

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]
Launch Ubuntu VMs using libvirt/KVM with cloud-init configuration.
OPTIONS:
  -n, --num-vms NUM       Number of VMs to create (default: 1, max: 5)
  -m, --memory GB         Memory per VM in GB (default: 1, max: 8)
  -c, --cpus NUM          Number of CPUs per VM (default: 1, max: 2)
  -d, --disk-size GB      Disk size in GB (default: 10, min: 10)
  -g, --github USER       GitHub username for SSH key import (required)
  -h, --help              Show this help message and exit
EXAMPLES:
  $(basename "$0") -g myuser
  $(basename "$0") -n 3 -m 2 -c 2 -d 20 -g myuser
  $(basename "$0") --num-vms 5 --memory 4 --github myuser
NOTES:
  - VMs will be assigned IPs in the range 192.168.1.100-150
  - The script will automatically find available network octets
  - Ubuntu Noble cloud image will be downloaded if not present
EOF
  exit 0
}

NUM_VMS=1
MEMORY=1
CPUS=1
DISK_SIZE=10
GITHUB_USER=""

while [[ $# -gt 0 ]]; do
  case $1 in
  -n | --num-vms)
    NUM_VMS="$2"
    shift 2
    ;;
  -m | --memory)
    MEMORY="$2"
    shift 2
    ;;
  -c | --cpus)
    CPUS="$2"
    shift 2
    ;;
  -d | --disk-size)
    DISK_SIZE="$2"
    shift 2
    ;;
  -g | --github)
    GITHUB_USER="$2"
    shift 2
    ;;
  -h | --help)
    usage
    ;;
  *)
    echo "Error: Unknown option $1"
    echo "Use -h or --help for usage information."
    exit 1
    ;;
  esac
done

if [ -z "$GITHUB_USER" ]; then
  echo "Error: GitHub username is required for SSH key import."
  echo "Use -g or --github to specify your GitHub username."
  echo "Use -h or --help for usage information."
  exit 1
fi

BASE_IMG="noble-server-cloudimg-amd64.img"
IMG_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
IMG_DIR="/var/lib/libvirt/images"
SUBNET="192.168.122"
GATEWAY="$SUBNET.1"
DHCP_START=2
DHCP_END=254

if [ $NUM_VMS -gt $((DHCP_END - DHCP_START)) ]; then
  echo "Error: Max 5 VMs to stay within $DHCP_START-$DHCP_END range."
  exit 1
fi

if [ $MEMORY -gt 8 ]; then
  echo "Error: Max memory is 8GB"
  exit 1
fi

if [ $CPUS -gt 2 ]; then
  echo "Error: Max CPUs is 2"
  exit 1
fi

if [ $DISK_SIZE -lt 10 ]; then
  echo "Error: Disk size must be at least 10GB to accommodate base image."
  exit 1
fi

if [ ! -f "$IMG_DIR/$BASE_IMG" ]; then
  echo "Downloading Ubuntu Noble cloud image..."
  wget -O "$IMG_DIR/$BASE_IMG" "$IMG_URL"
  if [ $? -ne 0 ]; then
    echo "Error: Failed to download the base image from $IMG_URL"
    exit 1
  fi
  echo "Base image downloaded successfully."
fi

is_octet_available() {
  local octet=$1
  local ip="$SUBNET.$octet"

  for vm in $(virsh list --all --name 2>/dev/null); do
    if [ -n "$vm" ]; then
      if [ "$vm" = "server-$octet" ]; then
        return 1
      fi
    fi
  done

  if ping -c 1 -W 1 "$ip" &>/dev/null; then
    return 1
  fi

  return 0
}

AVAILABLE_OCTETS=()
for octet in $(seq $DHCP_START $DHCP_END); do
  if is_octet_available $octet; then
    AVAILABLE_OCTETS+=($octet)
  fi
  if [ ${#AVAILABLE_OCTETS[@]} -ge $NUM_VMS ]; then
    break
  fi
done

if [ ${#AVAILABLE_OCTETS[@]} -lt $NUM_VMS ]; then
  echo "Error: Not enough available network addresses. Found ${#AVAILABLE_OCTETS[@]}, need $NUM_VMS."
  echo "Available range is $SUBNET.$DHCP_START-$DHCP_END. Some addresses may already be in use."
  exit 1
fi

echo "Found ${#AVAILABLE_OCTETS[@]} available network addresses."

for i in $(seq 0 $(($NUM_VMS - 1))); do
  OCTET=${AVAILABLE_OCTETS[$i]}
  HOSTNAME="server-$OCTET"
  IMG="$IMG_DIR/vm-$OCTET.qcow2"
  SEED="$IMG_DIR/seed-$OCTET.iso"
  USER_DATA="user-data-$OCTET.yaml"
  NETWORK_DATA="network-data-$OCTET.yaml"

  qemu-img create -f qcow2 -F qcow2 -b "$IMG_DIR/$BASE_IMG" "$IMG" ${DISK_SIZE}G

  cat <<EOF >"$USER_DATA"
#cloud-config
hostname: $HOSTNAME
package_update: true
package_upgrade: true
users:
  - name: ubuntu
    shell: /bin/bash
    groups: [users, sudo]
    sudo: "ALL=(ALL) NOPASSWD:ALL"
    lock_passwd: false
    passwd: 123456789
    ssh_import_id:
      - gh:$GITHUB_USER
packages:
  - apt-transport-https
  # - xorg
  # - xterm
  # - openbox
  # - chromium-browser
  # - spice-vdagent
  # - xvfb
  # - gdebi
  - make
  - wget
  - curl
  - build-essential
runcmd:
  - wget -O containerd.tar.gz https://github.com/containerd/containerd/releases/download/v2.3.3/containerd-2.3.3-linux-amd64.tar.gz
  - sudo tar Cxzvf /usr/local containerd.tar.gz
  - sudo mkdir -p /usr/local/lib/systemd/system/
  - sudo wget -O /usr/local/lib/systemd/system/containerd.service https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
  - sudo systemctl daemon-reload
  - sudo systemctl enable --now containerd
  - wget -O runc.amd64 https://github.com/opencontainers/runc/releases/download/v1.5.1/runc.amd64
  - sudo install -m 755 runc.amd64 /usr/local/sbin/runc
  - wget -O cni-plugins.tgz https://github.com/containernetworking/plugins/releases/download/v1.9.1/cni-plugins-linux-amd64-v1.9.1.tgz
  - mkdir -p /opt/cni/bin
  - sudo tar Cxzvf /opt/cni/bin cni-plugins.tgz
  - containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
  - sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
  - sudo apt-get update
  - sudo apt-get install -y apt-transport-https ca-certificates curl gpg
  - curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.36/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
  - echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.36/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
  - sudo apt-get update
  - sudo apt-get install -y kubelet kubeadm kubectl
  - sudo apt-mark hold kubelet kubeadm kubectl

  # - mkdir -p /home/ubuntu/.config/openbox
  # - wget https://raw.githubusercontent.com/Mikachu/openbox/refs/heads/master/data/rc.xml -P /home/ubuntu/.config/openbox
  # - sed -i '/<\/keyboard>/i \   <keybind key="C-A-t">\n     <action name="Execute">\n       <command>xterm</command>\n     </action>\n   </keybind>' /home/ubuntu/.config/openbox/rc.xml
  # - sed -i '/<\/keyboard>/i \   <keybind key="C-A-c">\n     <action name="Execute">\n       <command>chromium</command>\n     </action>\n   </keybind>' /home/ubuntu/.config/openbox/rc.xml
  # - sed -i '/<\/keyboard>/i \   <keybind key="C-A-g">\n     <action name="Execute">\n       <command>google-chrome</command>\n     </action>\n   </keybind>' /home/ubuntu/.config/openbox/rc.xml
  # - sudo apt-get install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev liblzma-dev
  # - cd /tmp/
  # - wget https://www.python.org/ftp/python/3.13.7/Python-3.13.7.tgz
  # - tar xzf Python-3.13.7.tgz
  # - cd Python-3.13.7
  # - sudo ./configure --enable-optimizations
  # - sudo make -j\$(nproc)
  # - sudo make altinstall
  # - sudo ln -s /usr/local/bin/python3.13 /usr/local/bin/python
  # - sudo ln -s /usr/local/bin/pip3.13 /usr/local/bin/pip
  # - wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
  # - sudo apt install ./google-chrome-stable_current_amd64.deb
  # - sudo mkdir -p /home/ubuntu/.config/google-chrome/Crashpad
  # - echo 'if [[ -z \$DISPLAY ]] && [[ \$(tty) = /dev/tty1 ]]; then exec startx; else export DISPLAY=:0; fi' | sudo tee -a /home/ubuntu/.profile
  # - echo "alias displays='ps e | grep -Po " DISPLAY=[\\.0-9A-Za-z:]* " | sort -u'" >> /home/ubuntu/.bashrc
  # - sudo groupadd -g 3001 docker
  # - sudo usermod -aG docker ubuntu
  # - curl -fsSL https://get.docker.com -o get-docker.sh
  # - sudo sh get-docker.sh
  # - sudo reboot
EOF

  cat <<EOF >"$NETWORK_DATA"
#cloud-config
network:
  version: 2
  ethernets:
    interface0:
      match:
        name: "en*s0"
      dhcp4: false
      addresses: [$SUBNET.$OCTET/24]
      routes:
        - to: default
          via: $GATEWAY
      nameservers:
        addresses: [8.8.8.8,8.8.4.4]
EOF

  echo "$(cat $USER_DATA)"
  echo "$(cat $NETWORK_DATA)"

  cloud-localds --network-config "$NETWORK_DATA" "$SEED" "$USER_DATA"

  rm "$USER_DATA"
  rm "$NETWORK_DATA"

  virt-install \
    --name "$HOSTNAME" \
    --memory $(($MEMORY * 1024)) \
    --vcpus $CPUS \
    --disk path="$IMG",bus=virtio,format=qcow2 \
    --disk path="$SEED",bus=virtio,format=raw \
    --network default \
    --os-variant ubuntu24.04 \
    --graphics spice,listen=0.0.0.0 \
    --channel spicevmc \
    --video virtio \
    --import \
    --noautoconsole

  echo "Launched VM $((i + 1)): $HOSTNAME with IP $SUBNET.$OCTET (disk size: ${DISK_SIZE}GB)"
done

echo "All $NUM_VMS VMs launched. Use 'virsh list --all' to see VMs, 'virsh start/stop/destroy <name>', 'virsh console <name>' for access. Clean up images/ISOs when done."
