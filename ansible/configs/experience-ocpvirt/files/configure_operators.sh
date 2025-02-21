#!/bin/sh -xe
cat << EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-cnv
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-cnv
  namespace: openshift-cnv
spec:
  targetNamespaces:
  - openshift-cnv
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-cnv
  namespace: openshift-cnv
spec:
  source: redhat-operators
  sourceNamespace: openshift-marketplace
  name: kubevirt-hyperconverged
  channel: stable
EOF

until oc get hyperconvergeds.hco.kubevirt.io; do sleep 60; done

sleep 30

export VERSION=$(curl https://storage.googleapis.com/kubevirt-prow/release/kubevirt/kubevirt/stable.txt)
wget -O /usr/bin/virtctl  https://github.com/kubevirt/kubevirt/releases/download/${VERSION}/virtctl-${VERSION}-linux-amd64
chmod 775 /usr/bin/virtctl

cat << EOF | oc apply -f -
---
apiVersion: hco.kubevirt.io/v1beta1
kind: HyperConverged
metadata:
  name: kubevirt-hyperconverged
  namespace: openshift-cnv
spec:
EOF

cat << EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-mtv
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-mtv
  namespace: openshift-mtv
spec:
  targetNamespaces:
  - openshift-mtv
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-mtv
  namespace: openshift-mtv
spec:
  channel: release-v2.5
  installPlanApproval: Automatic
  name: mtv-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

until oc get forkliftcontrollers.forklift.konveyor.io; do sleep 60; done

cat << EOF | oc apply -f -
---
apiVersion: forklift.konveyor.io/v1beta1
kind: ForkliftController
metadata:
  name: forklift-controller
  namespace: openshift-mtv
spec:
  olm_managed: true
EOF

cat << EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-nmstate
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: openshift-nmstate
  namespace: openshift-nmstate
spec:
  targetNamespaces:
  - openshift-nmstate
EOF

cat << EOF| oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: openshift-nmstate
  namespace: openshift-nmstate
spec:
  channel: stable
  installPlanApproval: Automatic
  name: kubernetes-nmstate-operator
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

until oc get nmstates.nmstate.io; do sleep 60; done

cat << EOF | oc apply -f -
---
apiVersion: nmstate.io/v1
kind: NMState
metadata:
  name: nmstate
EOF

cat << EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: metallb-system
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1
kind: OperatorGroup
metadata:
  name: metallb-system
  namespace: metallb-system
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: metallb-system
  namespace: metallb-system
spec:
  channel: stable
  name: metallb-operator
  source: redhat-operators 
  sourceNamespace: openshift-marketplace
EOF

until oc get metallbs.metallb.io; do sleep 60; done

cat << EOF | oc apply -f -
---
apiVersion: metallb.io/v1beta1
kind: MetalLB
metadata:
  name: metallb
  namespace: metallb-system
EOF

cat << EOF | oc apply -f -
---
apiVersion: operators.coreos.com/v1alpha1
kind: Subscription
metadata:
  name: web-terminal
  namespace: openshift-operators
spec:
  channel: fast
  installPlanApproval: Automatic
  name: web-terminal
  source: redhat-operators
  sourceNamespace: openshift-marketplace
EOF

cat <<EOF | oc apply -f -
---
apiVersion: v1
kind: Namespace
metadata:
  name: openshift-terminal
EOF

until oc get DevWorkspace; do sleep 30; done

sleep 30

cat << EOF | oc apply -f -
---
apiVersion: workspace.devfile.io/v1alpha2
kind: DevWorkspace
metadata:
  annotations:
    controller.devfile.io/devworkspace-source: web-terminal
    controller.devfile.io/restricted-access: 'true'
  name: webterminal
  namespace: openshift-terminal
  finalizers:
  - rbac.controller.devfile.io
  labels:
    console.openshift.io/terminal: 'true'
spec:
  routingClass: web-terminal
  started: true
  template:
    components:
    - name: web-terminal-tooling
      plugin:
        kubernetes:
          name: web-terminal-tooling
          namespace: openshift-operators
    - name: web-terminal-exec
      plugin:
        kubernetes:
          name: web-terminal-exec
          namespace: openshift-operators
EOF
