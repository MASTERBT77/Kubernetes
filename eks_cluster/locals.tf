locals {
  environment = var.environment_name
  service     = var.service_name
  env  = local.environment
  name = "${local.environment}-${local.service}"
  # Mapping
  cluster_version            = var.cluster_version
  argocd_secret_manager_name = var.argocd_secret_manager_name_suffix
  eks_admin_role_name        = var.eks_admin_role_name
  addons_repo_url            = var.addons_repo_url  
  workload_repo_path         = var.workload_repo_path
  workload_repo_url          = var.workload_repo_url
  workload_repo_revision     = var.workload_repo_revision 
  tag_val_vpc            = local.environment
  tag_val_public_subnet  = "${local.environment}-public-"
  tag_val_private_subnet = "${local.environment}-private-"
  node_group_name = "managed-ondemand"

  addon_context = {
    eks_cluster_id       = module.eks.cluster_name
    aws_eks_cluster_endpoint = module.eks.cluster_endpoint
    eks_oidc_provider    = module.eks.oidc_provider
    eks_cluster_version  = var.cluster_version
    aws_caller_identity_account_id = data.aws_caller_identity.current.account_id
    aws_caller_identity_arn        = data.aws_caller_identity.current.arn
    aws_partition_id               = data.aws_partition.current.partition
    aws_region_name                = data.aws_region.current.name
    eks_oidc_issuer_url            = module.eks.cluster_oidc_issuer_url
    eks_oidc_provider_arn          = module.eks.oidc_provider_arn
    tags                           = local.tags
    irsa_iam_role_path             = var.irsa_iam_role_path
    irsa_iam_permissions_boundary  = var.irsa_iam_permissions_boundary
  }




  tags = {
    Blueprint  = local.name
    GithubRepo = "github.com/aws-ia/terraform-aws-eks-blueprints"
  }
  
  #---------------------------------------------------------------
  # ARGOCD ADD-ON APPLICATION
  #---------------------------------------------------------------

  #At this time (with new v5 addon repository), the Addons need to be managed by Terrform and not ArgoCD
  addons_application = {
    path                = "chart"
    repo_url            = local.addons_repo_url
    add_on_application  = true
  }

  #---------------------------------------------------------------
  # ARGOCD WORKLOAD APPLICATION
  #---------------------------------------------------------------

  workload_application = {
    path                = local.workload_repo_path # <-- we could also to blue/green on the workload repo path like: envs/dev-blue / envs/dev-green
    repo_url            = local.workload_repo_url
    target_revision     = local.workload_repo_revision

    add_on_application  = false
    values = {
      labels = {
        env   = local.env
      }
      spec = {
        source = {
          repoURL        = local.workload_repo_url
          targetRevision = local.workload_repo_revision
        }
        blueprint                = "terraform"
        clusterName              = local.name
        karpenterInstanceProfile = module.karpenter.instance_profile_name 
        env                      = local.env
      }
    }
  }  

}
