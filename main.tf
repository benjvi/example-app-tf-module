resource "cloudflare_record" "webapp" {
  domain = "${var.cloudflare_domain}"
  name   = "webapp.${terraform.workspace}"
  value  = "${kubernetes_service.app-service.load_balancer_ingress.0.ip}"
  type   = "A"
  ttl    = 120
}

resource "kubernetes_service" "app-service" {
  metadata {
    name = "app-service"
    namespace = "${terraform.workspace}"
  }
  spec {
    selector {
      app = "snap"
    }
    session_affinity = "ClientIP"
    port {
      port = 80
      target_port = 8000
    }

    type = "LoadBalancer"
  }
}

data "template_file" "app-deployment" {
  template = "${file("${path.module}/manifests/app-deployment.yaml")}"

  vars {
    namespace = "${terraform.workspace}"
  }
}

resource "k8s_manifest" "app-deployment" {
  content = "${data.template_file.app-deployment.rendered}"
}