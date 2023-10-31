resource "kubernetes_namespace" "kubeflow" {
  metadata {
    labels = {
      control-plane   = "kubeflow"
      istio-injection = "enabled"
    }

    name = "kubeflow"
  }
}

module "kubeflow_issuer" {
  source = "./modules/kubeflow-issuer"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-issuer-chart"
  }

  addon_context = var.addon_context
  depends_on    = [kubernetes_namespace.kubeflow]
}

module "kubeflow_istio" {
  source = "./modules/kubeflow-istio"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-istio/"
  } 
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_issuer]
}

module "kubeflow_dex" {
  source = "./modules/kubeflow-dex"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-dex"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_istio]
}

module "kubeflow_oidc_authservice" {
  source = "./modules/kubeflow-oidc-auth"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-oidc-auth"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_dex]
}

module "kubeflow_knative_serving" {
  source = "./modules/knative-serving"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/knative-serving"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_oidc_authservice]
}

module "kubeflow_cluster_local_gateway" {
  source = "./modules/gateway"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/gateway"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_knative_serving]
}

module "kubeflow_knative_eventing" {
  source = "./modules/knative-eventing"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/knative-eventing"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_cluster_local_gateway]
}

module "kubeflow_roles" {
  source = "./modules/kubeflow-roles"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-roles"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_knative_eventing]
}

module "kubeflow_istio_resources" {
  source = "./modules/kubeflow-istio-resources"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-istio-resources"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_roles]
}

module "kubeflow_pipelines" {
  source = "./modules/kubeflow-pipelines"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kubeflow-pipelines"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_istio_resources]
}

module "kubeflow_kserve" {
  source = "./modules/kserve"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/kserve"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_pipelines]
}

module "kubeflow_models_web_app" {
  source = "./modules/models-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/models-web-app"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_kserve]
}

module "kubeflow_katib" {
  source = "./modules/katib"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/katib"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_models_web_app]
}

module "kubeflow_central_dashboard" {
  source = "./modules/central-dashboard"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/central-dashboard"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_katib]
}

module "kubeflow_admission_webhook" {
  source = "./modules/admission-webhook"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/admission-webhook"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_central_dashboard]
}

module "kubeflow_notebook_controller" {
  source = "./modules/notebook-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/notebook-controller"
    set = [
      {
        name  = "cullingPolicy.cullIdleTime",
        value = var.notebook_cull_idle_time
      },
      {
        name  = "cullingPolicy.enableCulling",
        value = var.notebook_enable_culling
      },
      {
        name  = "cullingPolicy.idlenessCheckPeriod",
        value = var.notebook_idleness_check_period
      }
    ]
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_admission_webhook]
}

module "kubeflow_jupyter_web_app" {
  source = "./modules/jupyter-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/jupyter-web-app"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_notebook_controller]
}

module "kubeflow_profiles_and_kfam" {
  source = "./modules/profiles-and-kfam"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/profiles-and-kfam"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_jupyter_web_app]
}

module "kubeflow_volumes_web_app" {
  source = "./modules/volumes-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/volumes-web-app"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_profiles_and_kfam]
}

module "kubeflow_tensorboards_web_app" {
  source = "./modules/tensorboards-web-app"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/tensorboards-web-app"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_volumes_web_app]
}

module "kubeflow_tensorboard_controller" {
  source = "./modules/tensorboard-controller"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/tensorboard-controller"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_tensorboards_web_app]
}

module "kubeflow_training_operator" {
  source = "./modules/training-operator"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/training-operator"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_tensorboard_controller]
}

module "kubeflow_aws_telemetry" {
  count  = var.enable_aws_telemetry ? 1 : 0
  source = "./modules/aws-telemetry"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/aws-telemetry"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_training_operator]
}

module "kubeflow_user_namespace" {
  source = "./modules/user-namespace"
  helm_config = {
    chart = "${var.kf_helm_repo_path}/charts/user-namespace"
  }
  addon_context = var.addon_context
  depends_on    = [module.kubeflow_aws_telemetry]
}

module "ack_sagemaker" {
  source        = "./modules/ack-sagemaker-controller"
  addon_context = var.addon_context
}
