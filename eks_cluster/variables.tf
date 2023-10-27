variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}
variable "environment_name" {
  description = "The name of Environment Infrastructure stack, feel free to rename it. Used for cluster and VPC names."
  type        = string
  default     = "eks-dev"
}

variable "service_name" {
  description = "The name of the Suffix for the stack name"
  type        = string
  default     = "blue"
}

variable "cluster_version" {
  description = "The Version of Kubernetes to deploy"
  type        = string
  default     = "1.28"
}
variable "irsa_iam_role_path" {
  description = "IAM role path for IRSA roles"
  type        = string
  default     = "/"
}

variable "irsa_iam_permissions_boundary" {
  description = "IAM permissions boundary for IRSA roles"
  type        = string
  default     = ""
}
variable "eks_admin_role_name" {
  type        = string
  description = "Additional IAM role to be admin in the cluster"
  default     = "admineks"
}

variable "argocd_secret_manager_name_suffix" {
  type        = string
  description = "Name of secret manager secret for ArgoCD Admin UI Password"
  default     = "argocd-admin-secret"
}

variable "workload_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD workload deployment"
  default     = "https://github.com/MASTERBT77/eks-blueprints-workloads"
}

variable "workload_repo_revision" {
  type        = string
  description = "Git repo revision in workload_repo_url for the ArgoCD workload deployment"
  default     = "main"
}

variable "workload_repo_path" {
  type        = string
  description = "Git repo path in workload_repo_url for the ArgoCD workload deployment"
  default     = "envs/dev"
}

variable "addons_repo_url" {
  type        = string
  description = "Git repo URL for the ArgoCD addons deployment"
  default     = "https://github.com/aws-samples/eks-blueprints-add-ons.git"
}

#kubeflow variables
variable "enable_aws_telemetry" {
  description = "Enable AWS telemetry component"
  type        = bool
  default     = true
}

variable "kf_helm_repo_path" {
  description = "Full path to the location of the helm repo for KF"
  type        = string
  default     = "../eks_cluster/KubeflowComponents"
}

variable "notebook_enable_culling" {
  description = "Enable Notebook culling feature. If set to true then the Notebook Controller will scale all Notebooks with Last activity older than the notebook_cull_idle_time to zero"
  type        = string
  default     = false
}

variable "notebook_cull_idle_time" {
  description = "If a Notebook's LAST_ACTIVITY_ANNOTATION from the current timestamp exceeds this value then the Notebook will be scaled to zero (culled). ENABLE_CULLING must be set to 'true' for this setting to take effect.(minutes)"
  type        = string
  default     = 30
}

variable "notebook_idleness_check_period" {
  description = "How frequently the controller should poll each Notebook to update its LAST_ACTIVITY_ANNOTATION (minutes)"
  type        = string
  default     = 5
}