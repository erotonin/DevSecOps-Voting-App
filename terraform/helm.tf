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

  depends_on = [module.eks]
}

resource "helm_release" "sonarqube" {
  name             = "sonarqube"
  repository       = "https://SonarSource.github.io/helm-chart-sonarqube"
  chart            = "sonarqube"
  namespace        = "sonarqube"
  create_namespace = true
  timeout          = 900
  cleanup_on_fail  = true

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

  depends_on = [module.eks]
}

resource "time_sleep" "wait_for_argocd" {
  depends_on      = [helm_release.argocd]
  create_duration = "30s"
}

resource "null_resource" "argocd_app" {
  depends_on = [time_sleep.wait_for_argocd]

  triggers = {
    region       = var.aws_region
    cluster_name = var.cluster_name
  }

  provisioner "local-exec" {
    command = <<EOT
      aws eks update-kubeconfig --region ${var.aws_region} --name ${var.cluster_name}
      kubectl apply -f ../k8s/argocd-app.yaml
    EOT
  }

  provisioner "local-exec" {
    when    = destroy
    command = <<EOT
      aws eks update-kubeconfig --region ${self.triggers.region} --name ${self.triggers.cluster_name}
      kubectl delete -f ../k8s/argocd-app.yaml --ignore-not-found=true
      sleep 20
    EOT
  }
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  timeout          = 600
  cleanup_on_fail  = true

  set {
    name  = "grafana.service.type"
    value = "LoadBalancer"
  }

  set {
    name  = "grafana.adminPassword"
    value = "admin123"
  }

  depends_on = [module.eks]
}

resource "helm_release" "nexus" {
  name = "nexus"
  repository = "https://sonatype.github.io/helm3-charts/"
  chart = "nexus-repository-manager"
  namespace = "nexus"
  create_namespace = true
  timeout = 900

  set {
    name = "service.type"
    value = "LoadBalancer"
  }

  values = [
    <<-EOT
    image:
      tag: "3.68.1"
    nexus:
      env:
        - name: INSTALL4J_ADD_VM_PARAMS
          value: |-
            -Xms2703M -Xmx2703M
            -XX:MaxDirectMemorySize=2703M
            -XX:+UnlockExperimentalVMOptions
            -XX:+UseCGroupMemoryLimitForHeap
            -Djava.util.prefs.userRoot=/nexus-data/javaprefs
        - name: NEXUS_SECURITY_RANDOMPASSWORD
          value: "false"
    EOT
  ]

  set {
    name = "persistence.enabled"
    value = "false"
  }

  depends_on = [module.eks]
}

resource "time_sleep" "wait_for_nexus" {
  depends_on      = [helm_release.nexus]
  create_duration = "180s" 
}

resource "kubernetes_job" "nexus_setup_repos" {
  depends_on = [time_sleep.wait_for_nexus]

  metadata {
    name      = "nexus-setup-repos"
    namespace = "nexus"
  }

  spec {
    template {
      metadata {
        name = "nexus-setup-repos"
      }
      spec {
        container {
          name    = "curl"
          image   = "curlimages/curl:latest"
          command = ["/bin/sh", "-c"]
          args = [
            replace(<<-EOT
            URL="http://nexus-nexus-repository-manager.nexus.svc.cluster.local:8081"
            
            # npm-proxy
            curl -u admin:admin123 -X POST "$URL/service/rest/v1/repositories/npm/proxy" -H "Content-Type: application/json" -d '{"name":"npm-proxy","online":true,"storage":{"blobStoreName":"default","strictContentTypeValidation":true},"proxy":{"remoteUrl":"https://registry.npmjs.org/","contentMaxAge":1440,"metadataMaxAge":1440},"negativeCache":{"enabled":true,"timeToLive":1440},"httpClient":{"blocked":false,"autoBlock":true,"connection":{"retries":0,"timeout":60,"enableCircularRedirects":false,"enableCookies":false}}}'
            
            # pypi-proxy
            curl -u admin:admin123 -X POST "$URL/service/rest/v1/repositories/pypi/proxy" -H "Content-Type: application/json" -d '{"name":"pypi-proxy","online":true,"storage":{"blobStoreName":"default","strictContentTypeValidation":true},"proxy":{"remoteUrl":"https://pypi.org/","contentMaxAge":1440,"metadataMaxAge":1440},"negativeCache":{"enabled":true,"timeToLive":1440},"httpClient":{"blocked":false,"autoBlock":true,"connection":{"retries":0,"timeout":60,"enableCircularRedirects":false,"enableCookies":false}}}'
            
            # nuget-proxy
            curl -u admin:admin123 -X POST "$URL/service/rest/v1/repositories/nuget/proxy" -H "Content-Type: application/json" -d '{"name":"nuget-proxy","online":true,"storage":{"blobStoreName":"default","strictContentTypeValidation":true},"proxy":{"remoteUrl":"https://api.nuget.org/v3/index.json","contentMaxAge":1440,"metadataMaxAge":1440},"negativeCache":{"enabled":true,"timeToLive":1440},"httpClient":{"blocked":false,"autoBlock":true,"connection":{"retries":0,"timeout":60,"enableCircularRedirects":false,"enableCookies":false}},"nugetProxy":{"queryCacheItemMaxAge":3600}}'
            EOT
            , "\r", "")
          ]
        }
        restart_policy = "OnFailure"
      }
    }
  }
}