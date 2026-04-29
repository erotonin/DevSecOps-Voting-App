resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  version          = "5.46.7"

  set {
    name  = "server.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "configs.secret.argocdServerAdminPassword"
    value = "$2b$10$wVFYNYEFx8ukoQAkG1MuoecZwKFUiMSVNZPCBEUhSnOrxT1LrU3Sm"
  }

  depends_on = [aws_eks_node_group.main]
}

resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  namespace        = "sonarqube"
  create_namespace = true

  set {
    name  = "community.enabled"
    value = "true"
  }

  set {
    name  = "service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "monitoringPasscode"
    value = "define_it"
  }

  depends_on = [aws_eks_node_group.main]
}

resource "null_resource" "argocd_app" {
  depends_on = [helm_release.argocd]

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region us-east-1 --name voting-app-cluster
      kubectl apply -f ../k8s/argocd-app.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      aws eks update-kubeconfig --region us-east-1 --name voting-app-cluster
      kubectl delete -f ../k8s/argocd-app.yaml --ignore-not-found=true
    EOT
  }
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  depends_on = [aws_eks_node_group.main]
}
