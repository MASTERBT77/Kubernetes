# Required for public ECR where Karpenter artifacts are hosted
provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}
# Find the user currently in use by AWS
data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_vpc" "vpc" {
  filter {
    name   = "tag:Name"
    values = [local.tag_val_vpc]
  }
}
data "aws_subnets" "private" {
  filter {
    name   = "tag:Name"
    values = ["${local.tag_val_private_subnet}*"]
  }
}
resource "aws_ec2_tag" "private_subnets" {
  for_each    = toset(data.aws_subnets.private.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.environment}-${local.service}"
  value       = "shared"
}

data "aws_subnets" "public" {
  filter {
    name   = "tag:Name"
    values = ["${local.tag_val_public_subnet}*"]
  }
}
#Add Tags for the new cluster in the VPC Subnets
resource "aws_ec2_tag" "public_subnets" {
  for_each    = toset(data.aws_subnets.public.ids)
  resource_id = each.value
  key         = "kubernetes.io/cluster/${local.environment}-${local.service}"
  value       = "shared"
}

#secret for argoCD
data "aws_secretsmanager_secret" "argocd" {
  name = "${local.argocd_secret_manager_name}.${local.environment}"
}
data "aws_secretsmanager_secret_version" "admin_password_version" {
  secret_id = data.aws_secretsmanager_secret.argocd.id
}

##modules
#tfsec:ignore:aws-eks-enable-control-plane-logging
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 19.15.2"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  vpc_id     = data.aws_vpc.vpc.id
  subnet_ids = data.aws_subnets.private.ids

  #we uses only 1 security group to allow connection with Fargate, MNG, and Karpenter nodes
  create_node_security_group = true
  eks_managed_node_groups = {
    initial = {
      node_group_name = local.node_group_name
      instance_types  = ["m5.large"]

      desired_size = 4
      min_size     = 1
      max_size     = 4
      
      subnet_ids   = data.aws_subnets.private.ids
    }
  }

  manage_aws_auth_configmap = true
  aws_auth_roles = flatten(
    [
      ### uncomment the following 2 lines to add teams roles
    # module.eks_blueprints_platform_teams.aws_auth_configmap_role,
    # [for team in module.eks_blueprints_dev_teams : team.aws_auth_configmap_role],
    {
     rolearn  = module.karpenter.role_arn
     username = "system:node:{{EC2PrivateDNSName}}"
     groups = [
       "system:bootstrappers",
       "system:nodes",
     ]
    },
    {
      rolearn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${local.eks_admin_role_name}" # The ARN of the IAM role
      username = "ops-role"                                                                                      # The user name within Kubernetes to map to the IAM role
      groups   = ["system:masters"]                                                                              # A list of groups within Kubernetes to which the role is mapped; Checkout K8s Role and Rolebindings
    }
  ]
  )

  tags = merge(local.tags, {
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    # (i.e. - at most, only one security group should have this tag in your account)
    "karpenter.sh/discovery" = "${local.environment}-${local.service}"
  })
}
data "aws_iam_role" "eks_admin_role_name" {
  count     = local.eks_admin_role_name != "" ? 1 : 0
  name = local.eks_admin_role_name
}

# Creates Karpenter native node termination handler resources and IAM instance profile
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 19.15.2"
  cluster_name           = module.eks.cluster_name
  irsa_oidc_provider_arn = module.eks.oidc_provider_arn
  create_irsa            = false # IRSA will be created by the kubernetes-addons module

  tags = local.tags
}


module "kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints?ref=blueprints-workshops/modules/kubernetes-addons"
  eks_cluster_id     = module.eks.cluster_name
  #---------------------------------------------------------------
  # ARGO CD ADD-ON
  #---------------------------------------------------------------

  enable_argocd         = true
  argocd_manage_add_ons = false  # Indicates that ArgoCD is responsible for managing/deploying Add-ons.

  argocd_applications = {
    #addons    = local.addons_application
    #workloads = local.workload_application #We comment it for now
  }

  argocd_helm_config = {
    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt(data.aws_secretsmanager_secret_version.admin_password_version.secret_string)
      }
    ]    
    set = [
      {
        name  = "server.service.type"
        value = "LoadBalancer"
      }
    ]
  }
  #---------------------------------------------------------------
  # EKS Managed AddOns
  # https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/
  #---------------------------------------------------------------
  enable_amazon_eks_coredns = true
  enable_amazon_eks_kube_proxy = true
  enable_amazon_eks_vpc_cni = true      
  enable_amazon_eks_aws_ebs_csi_driver = true
  enable_aws_efs_csi_driver = true
  enable_aws_cloudwatch_metrics = true
  #---------------------------------------------------------------
  # ADD-ONS - You can add additional addons here
  # https://aws-ia.github.io/terraform-aws-eks-blueprints/add-ons/
  #---------------------------------------------------------------
  enable_aws_load_balancer_controller  = true
  enable_aws_for_fluentbit             = true
  enable_metrics_server                = true
  enable_argo_rollouts                 = true
  enable_karpenter                     = true                                       
  karpenter_node_iam_instance_profile        = module.karpenter.instance_profile_name 
  karpenter_enable_spot_termination_handling = true  
  enable_cert_manager                 = true
  enable_cert_manager_csi_driver      = true
  #enable_kubecost                      = true   #kubectl port-forward --namespace kubecost deployment/kubecost-cost-analyzer 9090:9090                    
}




module "kubeflow_components" {
  source = "./KubeflowComponents"
  kf_helm_repo_path = var.kf_helm_repo_path
  addon_context                  = local.addon_context
  enable_aws_telemetry           = var.enable_aws_telemetry
  notebook_enable_culling        = var.notebook_enable_culling
  notebook_cull_idle_time        = var.notebook_cull_idle_time
  notebook_idleness_check_period = var.notebook_idleness_check_period
  tags = local.tags
}




