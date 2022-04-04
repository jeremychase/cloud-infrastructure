#!/bin/bash

# Temporary script for applying argocd manifests
kubectl apply -f namespace.yaml
kubectl -n argocd apply -f install.yaml
