

## 

curl -O https://raw.githubusercontent.com/kubernetes-sigs/aws-efs-csi-driver/master/docs/iam-policy-example.json

aws iam create-policy \
    --policy-name AmazonEKS_EFS_CSI_Driver_Policy \
    --policy-document file://iam-policy-example.json

eksctl create iamserviceaccount \
    --cluster testing-cluster \
    --namespace kube-system \
    --name efs-csi-controller-sa \
    --attach-policy-arn arn:aws:iam::557140368923:policy/AmazonEKS_EFS_CSI_Driver_Policy \
    --approve \
    --region us-east-1

## Install the Amazon EFS CSI driver using Helm or a manifest.

helm repo add aws-efs-csi-driver https://kubernetes-sigs.github.io/aws-efs-csi-driver/

helm repo update

helm upgrade -i aws-efs-csi-driver aws-efs-csi-driver/aws-efs-csi-driver \
    --namespace kube-system \
    --set image.repository=602401143452.dkr.ecr.us-east-1.amazonaws.com/eks/aws-efs-csi-driver \
    --set controller.serviceAccount.create=false \
    --set controller.serviceAccount.name=efs-csi-controller-sa

## 

vpc_id=$(aws eks describe-cluster \
    --name testing-cluster \
    --query "cluster.resourcesVpcConfig.vpcId" \
    --output text)

cidr_range=$(aws ec2 describe-vpcs \
    --vpc-ids $vpc_id \
    --query "Vpcs[].CidrBlock" \
    --output text \
    --region us-east-1)

security_group_id=$(aws ec2 create-security-group \
    --group-name MyEfsSecurityGroup \
    --description "My EFS security group" \
    --vpc-id $vpc_id \
    --output text)

aws ec2 authorize-security-group-ingress \
    --group-id $security_group_id \
    --protocol tcp \
    --port 2049 \
    --cidr $cidr_range

## Create an Amazon EFS file system for your Amazon EKS cluster.

file_system_id=$(aws efs create-file-system \
    --region us-east-1 \
    --performance-mode generalPurpose \
    --query 'FileSystemId' \
    --output text)

    aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$vpc_id" \
    --query 'Subnets[*].{SubnetId: SubnetId,AvailabilityZone: AvailabilityZone,CidrBlock: CidrBlock}' \
    --output table

---------------------------------------------------------------------
|                          DescribeSubnets                          |
+------------------+-------------------+----------------------------+
| AvailabilityZone |     CidrBlock     |         SubnetId           |
+------------------+-------------------+----------------------------+
|  us-east-1a      |  192.168.0.0/19   |  subnet-02cb743735f732184  |
|  us-east-1d      |  192.168.32.0/19  |  subnet-08f2854bcc08603b8  |
|  us-east-1a      |  192.168.64.0/19  |  subnet-065ccfa0a8edf69b8  |
|  us-east-1d      |  192.168.96.0/19  |  subnet-0ab07dd3c42b946f3  |
+------------------+-------------------+----------------------------+


aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id subnet-02cb743735f732184 \
    --security-groups $security_group_id

aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id subnet-08f2854bcc08603b8 \
    --security-groups $security_group_id

aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id subnet-065ccfa0a8edf69b8 \
    --security-groups $security_group_id

aws efs create-mount-target \
    --file-system-id $file_system_id \
    --subnet-id subnet-0ab07dd3c42b946f3 \
    --security-groups $security_group_id

