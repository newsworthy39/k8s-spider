#!/bin/bash

PLANEADDRESS=$(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
KUBETOKEN=$(kubeadm token create)
DIGEST=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')

echo "Token created, run: 'kubeadm join ${PLANEADDRESS} --token ${KUBETOKEN} --discovery-token-ca-cert-hash sha256:${DIGEST}' within 24-hours."
