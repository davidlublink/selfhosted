/*

This job was written while testing my cluster and I was able to trigger OOM-killer on my nomad clients.

This job is not a serious job.

*/


job "OOM-Killer" {
  datacenters = ["intranet"]
  type = "service"

  group "web" {
    count = 1000

    update {
      max_parallel     = 1
      min_healthy_time = "30s"
      healthy_deadline = "9m"
    }

         network {
              port "http" { 
                to = 80
                 }
         }

    task "web" {
      driver = "docker"

      config {
             ports=["http"]

        image = "httpd"
      }

      resources {
        memory = 64
      }

      service {

        name = "banana"
        port = "http"

             check {
                  type     = "http"
                  path    = "/index.html"
                  interval = "60s"
                  timeout  = "10s"
        }
      }

    }
  }
}
