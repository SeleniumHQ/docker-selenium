#!/bin/bash

echo "Set ENV variables"
CLUSTER=${CLUSTER:-"minikube"}
DOCKER_VERSION=${DOCKER_VERSION:-""}
HELM_VERSION=${HELM_VERSION:-"latest"}
KUBERNETES_VERSION=${KUBERNETES_VERSION:-$(curl -L -s https://dl.k8s.io/release/stable.txt)}

# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

echo "Installing Docker for AMD64 / ARM64"
sudo apt-get update -qq || true
sudo apt-get install -yq ca-certificates curl wget jq
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
   $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update -qq || true
if [ -n "${DOCKER_VERSION}" ]; then
  if [[ "${DOCKER_VERSION}" == "20.10"* ]]; then
    DOCKER_VERSION="=5:${DOCKER_VERSION}~3-0~$(. /etc/os-release; echo "$ID")-$(. /etc/os-release; echo "$VERSION_CODENAME")"
  else
    DOCKER_VERSION="=5:${DOCKER_VERSION}-1~$(. /etc/os-release; echo "$ID").$(. /etc/os-release; echo "$VERSION_ID")~$(. /etc/os-release; echo "$VERSION_CODENAME")"
  fi
  echo "Installing package docker-ce${DOCKER_VERSION}"
  ALLOW_DOWNGRADE="--allow-downgrades"
fi
sudo apt-get install -yq ${ALLOW_DOWNGRADE} docker-ce${DOCKER_VERSION} docker-ce-cli${DOCKER_VERSION}
sudo apt-get install -yq ${ALLOW_DOWNGRADE} containerd.io docker-buildx-plugin docker-compose-plugin gcc-aarch64-linux-gnu qemu-user-static
sudo chmod 666 /var/run/docker.sock
docker version
docker buildx version
docker buildx use default
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes --credential yes ;
else
    docker run --rm --privileged aptman/qus -- -r ;
    docker run --rm --privileged aptman/qus -s -- -p
fi
docker info
echo "==============================="
echo "Installing Docker compose for AMD64 / ARM64"
DOCKER_COMPOSE_VERSION="v2.26.0"
curl -fsSL -o ./docker-compose "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-$(uname -m)"
chmod +x ./docker-compose
sudo mv ./docker-compose /usr/libexec/docker/cli-plugins
docker compose version
echo "==============================="
echo "Install Docker SBOMs plugin"
curl -sSfL https://raw.githubusercontent.com/docker/sbom-cli-plugin/main/install.sh | sh -s --
docker sbom --version
echo "==============================="
if [ "${CLUSTER}" = "kind" ]; then
    echo "Installing kind for AMD64 / ARM64"
    curl -fsSL -o ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-$(dpkg --print-architecture)
    chmod +x ./kind
    sudo cp -frp ./kind /usr/local/bin/kind
    sudo ln -sf /usr/local/bin/kind /usr/bin/kind
    rm -rf kind
    kind version
    echo "==============================="
elif [ "${CLUSTER}" = "minikube" ]; then
    echo "Installing additional dependencies for running Minikube on none driver CRI-dockerd"
    echo "==============================="
    echo "Installing conntrack"
    sudo apt-get install -yq conntrack
    echo "==============================="
    echo "Installing Minikube"
    curl -sLO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-$(dpkg --print-architecture)
    sudo install minikube-linux-$(dpkg --print-architecture) /usr/local/bin/minikube
    minikube version
    rm -rf minikube-linux-$(dpkg --print-architecture)
    echo "==============================="
    echo "Installing Go"
    GO_VERSION="1.22.3"
    curl -sLO https://go.dev/dl/go$GO_VERSION.linux-$(dpkg --print-architecture).tar.gz
    sudo tar -xf go$GO_VERSION.linux-$(dpkg --print-architecture).tar.gz -C /usr/local
    rm -rf go$GO_VERSION.linux-$(dpkg --print-architecture).tar.gz*
    sudo ln -sf /usr/local/go/bin/go /usr/bin/go
    go version
    echo "==============================="
    echo "Installing CRI-CTL (CLI for CRI-compatible container runtimes)"
    CRICTL_VERSION="v1.30.0"
    curl -fsSL -o crictl.tar.gz https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-$(dpkg --print-architecture).tar.gz
    sudo tar -xf crictl.tar.gz -C /usr/local/bin
    rm -rf crictl.tar.gz
    crictl --version || true
    echo "==============================="
    echo "Installing CRI-Dockerd"
    CRI_DOCKERD_VERSION="0.3.14"
    curl -fsSL -o cri-dockerd.tgz https://github.com/Mirantis/cri-dockerd/releases/download/v$CRI_DOCKERD_VERSION/cri-dockerd-$CRI_DOCKERD_VERSION.$(dpkg --print-architecture).tgz
    sudo tar -xf cri-dockerd.tgz -C /tmp
    sudo mv /tmp/cri-dockerd/cri-dockerd /usr/local/bin/cri-dockerd
    sudo chmod +x /usr/local/bin/cri-dockerd
    rm -rf cri-dockerd.tgz cri-dockerd /tmp/cri-dockerd
    git clone -q https://github.com/Mirantis/cri-dockerd.git --branch v$CRI_DOCKERD_VERSION --single-branch -c advice.detachedHead=false
    sudo mkdir -p /etc/systemd/system
    sudo cp -a -f cri-dockerd/packaging/systemd/* /etc/systemd/system
    sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
    sudo systemctl daemon-reload
    sudo systemctl enable cri-docker.service
    sudo systemctl enable cri-docker.socket
    sudo systemctl status --no-pager cri-docker.socket || true
    rm -rf cri-dockerd
    cri-dockerd --version
    echo "==============================="
    echo "Installing CNI-Plugins (Container Network Interface)"
    CNI_PLUGIN_VERSION="v1.4.0"
    CNI_PLUGIN_TAR="cni-plugins-linux-$(dpkg --print-architecture)-$CNI_PLUGIN_VERSION.tgz"
    CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"
    curl -sLO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
    sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
    sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
    rm -rf "$CNI_PLUGIN_TAR"
    echo "==============================="
fi

echo "Installing kubectl for AMD64 / ARM64"
curl -fsSL -o ./kubectl "https://dl.k8s.io/release/${KUBERNETES_VERSION}/bin/linux/$(dpkg --print-architecture)/kubectl"
chmod +x ./kubectl
sudo cp -frp ./kubectl /usr/local/bin/kubectl
sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl
rm -rf kubectl
kubectl version --client
echo "==============================="

echo "Installing Helm for AMD64 / ARM64"
if [ "${HELM_VERSION}" = "latest" ]; then
    HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4)
fi
curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-$(dpkg --print-architecture).tar.gz
mkdir -p helm
tar -xf helm.tar.gz --strip-components 1 -C helm
sudo cp -frp helm/helm /usr/local/bin/helm
sudo ln -sf /usr/local/bin/helm /usr/bin/helm
rm -rf helm.tar.gz helm
helm version
echo "==============================="

echo "Installing chart-testing for AMD64 / ARM64"
CHART_TESTING_VERSION="3.10.1"
curl -fsSL -o ct.tar.gz https://github.com/helm/chart-testing/releases/download/v${CHART_TESTING_VERSION}/chart-testing_${CHART_TESTING_VERSION}_linux_$(dpkg --print-architecture).tar.gz
sudo mkdir -p /opt/ct
sudo tar -xzf ct.tar.gz -C /opt/ct
sudo chmod +x /opt/ct/ct
sudo ln -sf /opt/ct/ct /usr/bin/ct
sudo cp -frp /opt/ct/ct /usr/local/bin/ct
sudo cp -frp /opt/ct/etc /etc/ct
rm -rf ct.tar.gz
ct version
echo "==============================="
echo "Installing helm-docs for AMD64 / ARM64"
go install github.com/norwoodj/helm-docs/cmd/helm-docs@latest
$HOME/go/bin/helm-docs -h
echo "==============================="
echo "Installing envsubst for AMD64 / ARM64"
ENVSUBST_VERSION="v1.4.2"
ARCH=$(if [ "$(dpkg --print-architecture)" = "amd64" ]; then echo "x86_64"; else echo "$(dpkg --print-architecture)"; fi)
curl -fsSL https://github.com/a8m/envsubst/releases/download/${ENVSUBST_VERSION}/envsubst-$(uname -s)-${ARCH} -o envsubst
chmod +x envsubst
sudo mv envsubst /usr/local/bin
sudo ln -sf /usr/local/bin/envsubst /usr/bin/envsubst
echo "==============================="
