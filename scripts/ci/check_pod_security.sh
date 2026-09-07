#!/usr/bin/env bash
# Enforces the pod security requirements recorded in ADR-0019.
#
# These are stated in that decision as requirements rather than optional
# hardening, so they are verified mechanically rather than left to review:
#   containers do not run as root
#   privilege escalation is not permitted
#   images are pinned by digest, not by mutable tag
#   resource limits are declared, so one workload cannot starve another
set -euo pipefail

DIR=""
for candidate in infrastructure/kubernetes deploy; do
  if [ -d "$candidate" ]; then DIR="$candidate"; break; fi
done

if [ -z "$DIR" ]; then
  echo "No manifest directory found. Skipping."
  exit 0
fi

python3 - "$DIR" <<'PY'
import sys, re
from pathlib import Path

try:
    import yaml
except ImportError:
    print("PyYAML unavailable; cannot validate pod security. Failing closed.")
    sys.exit(1)

root = Path(sys.argv[1])
WORKLOADS = {'Deployment', 'StatefulSet', 'DaemonSet', 'Job', 'CronJob'}
failures = []

def check_pod_spec(spec, origin):
    sec = spec.get('securityContext') or {}
    if sec.get('runAsNonRoot') is not True:
        failures.append(f"{origin}: pod securityContext does not set runAsNonRoot: true")

    for c in spec.get('containers', []):
        name = c.get('name', '<unnamed>')
        where = f"{origin}, container {name}"

        csec = c.get('securityContext') or {}
        if csec.get('allowPrivilegeEscalation') is not False:
            failures.append(f"{where}: allowPrivilegeEscalation must be false")

        image = c.get('image', '')
        if '@sha256:' not in image:
            failures.append(f"{where}: image is not pinned by digest ({image})")

        res = c.get('resources') or {}
        if not res.get('limits'):
            failures.append(f"{where}: no resource limits declared")
        if not res.get('requests'):
            failures.append(f"{where}: no resource requests declared")

for path in sorted(root.rglob('*.y*ml')):
    try:
        docs = list(yaml.safe_load_all(path.read_text(encoding='utf-8')))
    except yaml.YAMLError as e:
        failures.append(f"{path}: not parseable as YAML ({e})")
        continue

    for doc in docs:
        if not isinstance(doc, dict):
            continue
        kind = doc.get('kind')
        if kind not in WORKLOADS:
            continue

        origin = f"{path}, {kind} {doc.get('metadata', {}).get('name', '<unnamed>')}"
        spec = doc.get('spec', {})
        if kind == 'CronJob':
            spec = spec.get('jobTemplate', {}).get('spec', {})
        pod = spec.get('template', {}).get('spec')
        if pod:
            check_pod_spec(pod, origin)

if failures:
    print("Pod security requirements not satisfied:")
    for f in failures:
        print(f"  {f}")
    print()
    print("These are requirements of ADR-0019, not optional hardening.")
    sys.exit(1)

print("Pod security requirements satisfied.")
PY
