job "haproxy" {
  datacenters = ["edge"]
  type = "service"

  group "haproxy" {
    count = 1
    volume "haproxy-config" {
             type      = "host"
             read_only = true
             source    = "haproxy-config"
        }  

    volume "letsencrypt" {
        type      = "host"
        read_only = true
        source    = "letsencrypt"
    }  
    update {
      max_parallel     = 1
      min_healthy_time = "30s"
      healthy_deadline = "9m"
    }
    restart {
      attempts = 3
      interval = "5m"
      delay = "25s"
      mode = "delay"
    }
    task "web" {
      driver = "docker"

      config {
        /*privileged = true */
        network_mode = "host"
        image = "haproxy"
      }

      volume_mount {
        volume = "haproxy-config"
        read_only = false
        destination = "/usr/local/etc/haproxy/"
            }
    volume_mount {
        volume = "letsencrypt"
        read_only = false
        destination = "/etc/letsencrypt"
    }

      resources {
        memory = 128
      }
    }
  }
}
