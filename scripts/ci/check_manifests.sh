#!/usr/bin/env bash
# Validates Kubernetes manifests against the API schema before they can be
# applied to a cluster. A manifest that is structurally invalid fails at apply
# time, which is later and more disruptive than failing in the pipeline.
set -euo pipefail

DIR=""
for candidate in infrastructure/kubernetes deploy; do
  if [ -d "$candidate" ]; then DIR="$candidate"; break; fi
done

if [ -z "$DIR" ]; then
  echo "No manifest directory found. Skipping."
  exit 0
fi

echo "Validating manifests in $DIR"

# kubeconform validates against published Kubernetes API schemas without
# requiring a cluster connection.
KUBECONFORM_VERSION="v0.6.7"
curl -sSL -o /tmp/kubeconform.tar.gz \
  "https://github.com/yannh/kubeconform/releases/download/${KUBECONFORM_VERSION}/kubeconform-linux-amd64.tar.gz"
tar -xzf /tmp/kubeconform.tar.gz -C /tmp kubeconform
chmod +x /tmp/kubeconform

# -strict rejects unknown fields, which catches typos in field names that
# Kubernetes would otherwise silently ignore.
/tmp/kubeconform \
  -strict \
  -summary \
  -ignore-missing-schemas \
  "$DIR"

echo "Manifest schema validation passed."
