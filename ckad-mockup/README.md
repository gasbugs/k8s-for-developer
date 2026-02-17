# CKAD Mockup Environment


## Quick Start

Run the following command to set up the entire environment:

```bash
bash setup.sh
```

This script will:
1. Create a Kind cluster with the configuration in `kind-mockup-config.yaml`.
2. Install Cilium CNI.
3. Install Traefik Ingress Controller with `traefik-values.yaml`.
4. Run `setup-lab.sh` to create namespaces and resources for the CKAD mock exam.
