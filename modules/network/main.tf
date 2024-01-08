resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
  auto_create_subnetworks = true
}

resource "google_compute_firewall" "firewall" {
  name = "terraform-firewall"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports = [ "80", "443" ]
  }

  source_ranges = [ "0.0.0.0/0" ]
}

resource "google_compute_global_address" "default" {
  name = "lb-ipv4-1"
}

resource "google_compute_health_check" "http_health_check" {
  name = "http-health-check"
  check_interval_sec = 30
  timeout_sec = 10
  healthy_threshold = 2
  unhealthy_threshold = 3

  http2_health_check {
    port = 80
  }
}

resource "google_compute_backend_service" "default" {
  name = "backend-service"
  protocol = "HTTP"
  port_name = "http"
  timeout_sec = 10

  health_checks = [google_compute_health_check.http_health_check.self_link]

}

resource "google_compute_url_map" "default" {
  name = "web-map"
  default_service = google_compute_backend_service.default.self_link
}

resource "google_compute_target_http_proxy" "default" {
  name = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

resource "google_compute_global_forwarding_rule" "default" {
  name = "http-content-rule"
  target = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  ip_address = google_compute_global_address.default.address
}


