Kubernetes Admin questions

SCHEDULE
- We have deployed a number of PODsas. They are labelled with tier, env and bu. How many PODs exist in the dev environment (env)?
  kubectl get pods --selector env=dev
- Identify the POD which is part of the prod environment, the finance BU and of frontend tier? (compose selector)
  kubectl get pods --selector env=prod,bu=finance,tier=frontend
- Create a taint on node01 with key of spray, value of mortein and effect of NoSchedule
 kubectl taint node node01 spray=mortein:NoSchedule
 kubectl taint node controlplane node-role.kubernetes.io/control-plane- (To remove a Taint)
- How many static pods exist in this cluster in all namespaces?

  kubectl get pods --all-namespaces -o custom-columns=NAME:.metadata.name,CONTROLLER:.metadata.ownerReferences[].kind,NAMESPACE:.metadata.namespace

- download metric server 
  git clone https://github.com/kodekloudhub/kubernetes-metrics-server.git

We need to take node01 out for maintenance. Empty the node of all applications and mark it unschedulable. 
   
   kubectl drain node01
   kubectl uncordon node01  --- to make schedulable again

What is the latest stable version of Kubernetes as of today?ç
   kubeadm upgrade plan

  Upgrade the controlplane components to exact version v1.27.0
    apt-mark unhold kubelet kubectl && \
    apt-get update && apt-get install -y kubelet=1.27.0-00 kubectl=1.27.0-00 && \
    apt-mark hold kubelet kubectl   

    for a worker node: 
  ssh firts, then: 

  #upgrade kubeadm 
  apt-mark unhold kubeadm && \
  apt-get update && apt-get install -y kubeadm=1.27.0-00 && \
  apt-mark hold kubeadm
  sudo kubeadm upgrade node

  #upgrade kubelet and kubectl ∫
  apt-mark unhold kubelet kubectl && \
  apt-get update && apt-get install -y kubelet=1.27.0-00 kubectl=1.27.0-00 && \
  apt-mark hold kubelet kubectl

  sudo systemctl daemon-reload
  sudo systemctl restart kubelet


Take a snapshot of the ETCD database using the built-in snapshot functionality.

  export ETCDCTL_API=3
  etcdctl snapshot 
  #### command to make backup
  ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key \
  snapshot save /opt/snapshot-pre-boot.db

  ### restore 
  ETCDCTL_API=3 etcdctl snapshot restore --data-dir /var/lib/etcd-from-backup /opt/snapshot-pre-boot.db


  -How many clusters are defined in the kubeconfig on the student-node?

  kubecetcl kubeconfig view

  - What is the default data directory used the for ETCD datastore used in cluster2?
    Remember, this cluster uses an External ETCD topology. 

    ps -ef |grep -i etcd 

  - How many nodes are part of the ETCD cluster that etcd-server is a part of?

  ETCDCTL_API=3 etcdctl --endpoints=https://192.37.190.3:2379 \
    --cacert=/etc/etcd/pki/ca.pem --cert=/etc/etcd/pki/etcd.pem --key=/etc/etcd/pki/etcd-key.pem member list
  
  ssh to node controlplane

  ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 \
    --cacert=/etc/kubernetes/pki/etcd/ca.crt --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key snapshot save /opt/cluster1.db

  copy to studen node

  scp cluster1-controlplane:/opt/cluster1.db /opt/  

  restore snpshot 

ETCDCTL_API=3 etcdctl snapshot restore /root/cluster2.db --data-dir /var/lib/etcd-data-new

#change permissions

 - chown etcd:etcd etcd-data-new/

 /etc/systemd/system ➜  vi etcd.service --- change data pat here! 

 systemctl daemon-reload
 systemctl restar etcd

 - Create a CertificateSigningRequest object with the name akshay with the contents of the akshay.csr file 


  cat <<EOF | kubectl apply -f -
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: akshay
spec:
  request: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURSBSRVFVRVNULS0tLS0KTUlJQ1ZqQ0NBVDRDQVFBd0VURVBNQTBHQTFVRUF3d0dZV3R6YUdGNU1JSUJJakFOQmdrcWhraUc5dzBCQVFFRgpBQU9DQVE4QU1JSUJDZ0tDQVFFQXdkcHU1WEhUcW5MY3RQR2NTdlMreDk0bVh6Sk4zcXZJSGVFNXY2bzVTTTkxCjlmVVBpVTFnYlc2bkk0VDZucFA0NEVYZ2lTRnAxSUpUaExWNWxzSEhzRXJsdFp1NkJ1cTZyRFMzMktLaUlFSEoKT214bmk3WGZON21IeE9GT3VZUHMxdFhmNGk1eHF2Z0NTR0hzazlubmdxdFU4a2dpcGFZYS85SG4wc2dlY1VLZApmMFIxem1oSHBQcTU5VDdwVlhxK3FDMmF5V0NkbTZ2VktVK25FR3R3MVhoSDJsdlZ1M01nTWN2akEwc3JudmxwCkR6VDMzQ1NLSFpXVWxpeGNEVmlWU1hsWWJMb0Y3NFBtYVlSeGJ3V1ZHK0RWUENzRE03enBvR09IbFV2eGI5dVYKSE5jRnIzWW9nK1hmN3FSaTJPZDhWZnk2c1U1Skh6TGt1bFRUSXE3WTN3SURBUUFCb0FBd0RRWUpLb1pJaHZjTgpBUUVMQlFBRGdnRUJBQnZUVVlrNjBCTWMwdXJZL1V3bjNCRHkwMjJkYWlpTVlSM2wvVTl1bFZqRTJMSFJFL0dDCnY0SEdjckJoTGQ5RGpRL1FnQmdVcVk2cGpFeDNSdjEwdThRc1dGaHJ5dDFhcjhOdEtuaGhJbE04NDArWE5PRHoKdno4MFVpdlRRU1lZbHVnOWFiYXFEL1BlaXFRUDArdGg1a3VKK01JbExJMUJUeEdaSTkyWDFPa09hRnA5cjg2WQpCQmJZZm8rQ2lGaE9rOEMvM05yelBPMWdUUXJEa0ZjMjBkdXowU1h4Wm9oY1FlY2RDdkNKZ3JQS2FFVzRHeHBOClllUzZrQTJEeVE2V2Z3ekV4LzNFYjFqVkRUUVdWZ095aWNNSHRVWlhjcWFJZXRhUmJDRVA2RVBXYXdnMFp2SEQKK1pReGEyaWhlS213MUJkQnAwWFhSYTBYSVg5cm9YQlpyRjA9Ci0tLS0tRU5EIENFUlRJRklDQVRFIFJFUVVFU1QtLS0tLQo=
  signerName: kubernetes.io/kube-apiserver-client
  usages:
  - client auth
EOF
  
to pass to base64 use: cat file.crc | base64 -w 0 (1 line)

-- to aprove kubectl certificate approve myuser

- I would like to use the dev-user to access test-cluster-1. Set the current context to the right one so I can do that.

   kubectl config use-context research --kubeconfig /root/my-kube-config

- We don't want to have to specify the kubeconfig file option on each command. Make the my-kube-config file the default kubeconfig.   

   mv /root/my-kube-config /root/.kube/config

- api resources for clusterroles and roles 

  kubectl api-resources
  kubectl create secret docker-registry private-reg-cred --docker-server=myprivateregistry.com:5000 --docker-username=dock_user --docker-password=dock_password --docker-email=dock_user@myprivateregistry.com

  

  