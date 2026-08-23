#!/bin/bash

# ################################################################
# Post Worker Creation

POWER_COUNT=2
IDX=0

# 1. Setup RMC
# Source https://github.com/ocp-power-automation/ocp4-playbooks/blob/main/playbooks/roles/ocp-customization/tasks/powervm_rmc.yaml
# Setup RMC using `oc` not Ansible

oc apply -f - <<'EOF'
apiVersion: project.openshift.io/v1
kind: Project
metadata:
  name: powervm-rmc
EOF

oc apply -f - <<'EOF'
apiVersion: v1
kind: ServiceAccount
metadata:
  name: powervm-rmc
  namespace: powervm-rmc
EOF

oc adm policy add-scc-to-user privileged -z powervm-rmc -n powervm-rmc

oc apply -f - <<'EOF'
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: powervm-rmc
  namespace: powervm-rmc
spec:
  selector:
    matchLabels:
      app: powervm-rmc
  template:
    metadata:
      labels:
        app: powervm-rmc
    spec:
      nodeSelector:
        kubernetes.io/arch: ppc64le
        node.openshift.io/os_id: rhcos
      restartPolicy: Always
      serviceAccountName: powervm-rmc
      hostNetwork: true
      containers:
      - name: powervm-rmc
        image: quay.io/powercloud/rsct-ppc64le:latest
        ports:
        - name: rmc-tcp
          hostPort: 657
          containerPort: 657
          protocol: TCP
        - name: rmc-udp
          hostPort: 657
          containerPort: 657
          protocol: UDP
        resources:
          requests:
            cpu: 100m
            memory: 500Mi
          limits:
            memory: 1Gi
        volumeMounts:
        - name: lib-modules
          mountPath: /lib/modules
          readOnly: true
        securityContext:
          privileged: true
          runAsUser: 0
      volumes:
      - name: lib-modules
        hostPath:
          path: /lib/modules
      tolerations:
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
EOF

# 2. Setup Localized NFS backed by VPC CSI
# TODO: This may not be needed

# 3. Remove all worker taints
# Note: not officially supported.
for NODE in $(oc get nodes -l kubernetes.io/arch=ppc64le -l node-role.kubernetes.io/worker= -oname)
do
    oc adm taint ${NODE} node.cloudprovider.kubernetes.io/uninitialized-
done

# 4. Approve and Issue certificates

READY_COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep -v NotReady | grep -c Ready)

# Approce CSR and Check Ready status
while [ "${READY_COUNT}" -ne "${POWER_COUNT}" ]
do
  
  echo "List of All Power Workers: "
  oc get nodes -l 'kubernetes.io/arch=ppc64le' -o json | jq -r '.items[] | .metadata.name'
  echo ""

  oc get csr -oname | xargs -I {} oc adm certificate approve {}

  # Wait for 30 seconds before we hammer the system
  echo "Sleeping before re-running - 30 seconds"
  sleep 30

  # Re-read the 'Ready' count
  READY_COUNT=$(oc get nodes -l kubernetes.io/arch=ppc64le | grep -v NotReady | grep -c Ready)

  # Increment counter
  IDX=$(($IDX + 1))

  # End Early... we've checked enough.
  if [ "${IDX}" -eq "60" ]
  then
    echo "Exceeded the wait time for CSRs to be generated and Worker/s node to be ready - > 30 minutes"
    echo "Printing all Nodes"
    oc get nodes -owide
    echo ""
    echo "Get All CSRs"
    oc get csr
    echo "Exiting with Error. Ready count - ${READY_COUNT} is not matching with expected Power Worker count - ${POWER_COUNT}"
    echo "Supplied Worker/s with prefix: '${MACHINE_PREFIX}' are not yet Ready."
    exit -1
  fi
done

echo ": Show the machineconfigpool/worker :"
oc get mcp worker
