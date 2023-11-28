#!/bin/bash
# Function to be executed on command failure
on_failure() {
    echo "There is step failed with exit status $?"
    exit $?
}

# Trap ERR signal and call on_failure function
trap 'on_failure' ERR

if [ "$(uname -m)" = "x86_64" ]; then
    echo "Installing kind for AMD64 / x86_64"
    curl -fsSL -o ./kind https://kind.sigs.k8s.io/dl/latest/kind-linux-amd64
    chmod +x ./kind
    sudo cp -frp ./kind /usr/local/bin/kind
    sudo ln -sf /usr/local/bin/kind /usr/bin/kind
    rm -rf kind
    kind version
    echo "==============================="

    echo "Installing kubectl for AMD64 / x86_64"
    curl -fsSL -o ./kubectl "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x ./kubectl
    sudo cp -frp ./kubectl /usr/local/bin/kubectl
    sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl
    rm -rf kubectl
    kubectl version --client
    echo "==============================="

    echo "Installing Helm for AMD64 / x86_64"
    curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3
    chmod 700 get_helm.sh
    ./get_helm.sh
    rm -rf get_helm.sh
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
fi
