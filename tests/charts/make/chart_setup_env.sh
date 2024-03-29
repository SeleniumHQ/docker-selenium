#!/bin/bash

echo "Set ENV variables"
CLUSTER=${CLUSTER:-"minikube"}

# Function to be executed on command failure
on_failure() {
    local exit_status=$?
    echo "There is step failed with exit status $exit_status"
    exit $exit_status
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

if [ "$(uname -m)" = "x86_64" ]; then
    echo "Installing Docker for AMD64 / x86_64"
    sudo apt-get update -qq
    sudo apt-get install -yq ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
       $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update -qq
    sudo apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    sudo docker version
    echo "==============================="
    echo "Installing Docker compose for AMD64 / x86_64"
    DOCKER_COMPOSE_VERSION="v2.26.0"
    curl -fsSL -o ./docker-compose "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64"
    chmod +x ./docker-compose
    sudo mv ./docker-compose /usr/libexec/docker/cli-plugins
    docker compose version
    echo "==============================="
    if [ "${CLUSTER}" = "kind" ]; then
        echo "Installing kind for AMD64 / x86_64"
        curl -fsSL -o ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
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
        sudo apt-get install -y conntrack
        echo "==============================="
        echo "Installing Minikube"
        curl -sLO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
        sudo install minikube-linux-amd64 /usr/local/bin/minikube
        minikube version
        rm -rf minikube-linux-amd64
        echo "==============================="
        echo "Installing Go"
        GO_VERSION="1.21.6"
        curl -sLO https://go.dev/dl/go$GO_VERSION.linux-amd64.tar.gz
        sudo tar -xf go$GO_VERSION.linux-amd64.tar.gz -C /usr/local
        rm -rf go$GO_VERSION.linux-amd64.tar.gz*
        sudo ln -sf /usr/local/go/bin/go /usr/bin/go
        go version
        echo "==============================="
        echo "Installing CRI-CTL (CLI for CRI-compatible container runtimes)"
        CRICTL_VERSION="v1.26.0"
        curl -sLO https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/crictl-$CRICTL_VERSION-linux-amd64.tar.gz
        sudo tar -xf crictl-$CRICTL_VERSION-linux-amd64.tar.gz -C /usr/local/bin
        rm -rf crictl-$CRICTL_VERSION-linux-amd64.tar.gz
        crictl --version || true
        echo "==============================="
        echo "Installing CRI-Dockerd"
        CRI_DOCKERD_VERSION="v0.3.9"
        rm -rf cri-dockerd
        git clone -q https://github.com/Mirantis/cri-dockerd.git --branch $CRI_DOCKERD_VERSION --single-branch -c advice.detachedHead=false
        cd cri-dockerd || true
        sudo go get -v
        sudo go build -v -o /usr/local/bin/cri-dockerd
        sudo mkdir -p /etc/systemd/system
        sudo cp -a -f packaging/systemd/* /etc/systemd/system
        sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
        sudo systemctl daemon-reload
        sudo systemctl enable cri-docker.service
        sudo systemctl enable cri-docker.socket
        sudo systemctl status --no-pager cri-docker.socket || true
        cd .. || true
        rm -rf cri-dockerd
        cri-dockerd --version
        echo "==============================="
        echo "Installing CNI-Plugins (Container Network Interface)"
        CNI_PLUGIN_VERSION="v1.4.0"
        CNI_PLUGIN_TAR="cni-plugins-linux-amd64-$CNI_PLUGIN_VERSION.tgz"
        CNI_PLUGIN_INSTALL_DIR="/opt/cni/bin"
        curl -sLO "https://github.com/containernetworking/plugins/releases/download/$CNI_PLUGIN_VERSION/$CNI_PLUGIN_TAR"
        sudo mkdir -p "$CNI_PLUGIN_INSTALL_DIR"
        sudo tar -xf "$CNI_PLUGIN_TAR" -C "$CNI_PLUGIN_INSTALL_DIR"
        rm -rf "$CNI_PLUGIN_TAR"
        echo "==============================="
    fi

    echo "Installing kubectl for AMD64 / x86_64"
    curl -fsSL -o ./kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo cp -frp ./kubectl /usr/local/bin/kubectl
    sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl
    rm -rf kubectl
    kubectl version --client
    echo "==============================="

    echo "Installing Helm for AMD64 / x86_64"
    HELM_VERSION=${HELM_VERSION:-"v3.14.3"}
    curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz
    mkdir -p helm
    tar -xf helm.tar.gz --strip-components 1 -C helm
    sudo cp -frp helm/helm /usr/local/bin/helm
    sudo ln -sf /usr/local/bin/helm /usr/bin/helm
    rm -rf helm.tar.gz helm
    helm version
    echo "==============================="

    echo "Installing chart-testing for AMD64 / x86_64"
    curl -fsSL -o ct.tar.gz https://github.com/helm/chart-testing/releases/download/v3.10.1/chart-testing_3.10.1_linux_amd64.tar.gz
    sudo mkdir -p /opt/ct
    sudo tar -xzf ct.tar.gz -C /opt/ct
    sudo chmod +x /opt/ct/ct
    sudo ln -sf /opt/ct/ct /usr/bin/ct
    sudo cp -frp /opt/ct/ct /usr/local/bin/ct
    sudo cp -frp /opt/ct/etc /etc/ct
    rm -rf ct.tar.gz
    ct version
    echo "==============================="
    echo "Installing envsubst for AMD64 / x86_64"
    curl -fsSL https://github.com/a8m/envsubst/releases/download/v1.4.2/envsubst-`uname -s`-`uname -m` -o envsubst
    chmod +x envsubst
    sudo mv envsubst /usr/local/bin
    sudo ln -sf /usr/local/bin/envsubst /usr/bin/envsubst
    echo "==============================="
fi
