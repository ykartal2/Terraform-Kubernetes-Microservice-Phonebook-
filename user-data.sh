#! /bin/bash
apt-get update -y
apt-get upgrade -y
hostnamectl set-hostname kube-master
sudo apt-get install -y apt-transport-https ca-certificates curl gpg
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
apt-get update
apt-get install -y kubelet=1.29.0-1.1 kubeadm=1.29.0-1.1 kubectl=1.29.0-1.1 kubernetes-cni docker.io
apt-mark hold kubelet kubeadm kubectl
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu
newgrp docker
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system
mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd
kubeadm config images pull
kubeadm init --pod-network-cidr=10.244.0.0/16 --ignore-preflight-errors=All
mkdir -p /home/ubuntu/.kube
cp -i /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
chown ubuntu:ubuntu /home/ubuntu/.kube/config
su - ubuntu -c 'kubectl apply -f https://github.com/coreos/flannel/raw/master/Documentation/kube-flannel.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.24/deploy/local-path-storage.yaml'
sudo -i -u ubuntu kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
sudo -i -u ubuntu kubectl taint nodes kube-master node-role.kubernetes.io/control-plane:NoSchedule-
cd /home/ubuntu
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/mysql-secret.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/pv-pvc.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/mysql-service.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/mysql-deploy.yml'
su - ubuntu -c 'sleep 90'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/web-deploy.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/resultserver-service.yml'
su - ubuntu -c 'kubectl apply -f https://raw.githubusercontent.com/ykartal2/K8s-Microservice-Phonebook-App/main/k8s/web-service.yml'











