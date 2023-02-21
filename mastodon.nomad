/*
 * author David Lublink
 * This job deploys a mastodon instance.

 You must set the following nomad variables before you run this job : 

nomad/jobs/mastodon
DB_PASS
TZ
OTP_SECRET
SECRET_KEY_BASE
LOCAL_DOMAIN
WEB_DOMAIN

More details on variables can be found here :

https://hub.docker.com/r/linuxserver/mastodon


You need to create a volume  'mastodon' that will be used to store the postgresql data.


Troubleshooting notes : 

1. Port 80 always redirects to https, so test with https
2. Your WEB_DOMAIN must match the domain in the URL used to access the page



Notes on my setup :

I have an haproxy running on the edge of my nomad network to expose this service publicly. 

backend mastodon
    mode http
    server-template four 1 _mastodon._tcp.service.consul resolvers consul resolve-opts allow-dup-ip resolve-prefer ipv4 check ssl verify none



This has not been tested with federation.


 * activate all users via postgresql
 UPDATE users SET confirmed_at = confirmation_sent_at ;
 */

job "Mastodon" {
  datacenters = ["intranet"]
  type = "service"

  group "main" {
    count = 1

    volume "mastodon" {
             type      = "host"
             read_only = false
             source    = "mastodon"
        }

    update {
      max_parallel     = 1
      min_healthy_time = "30s"
      healthy_deadline = "9m"
    }

         network {

            port "http" {
                static = 443
                 }

            port "database" { 
              to = 5432
                }
            port "redis" { 
              to = 6379
                }
         }


    task "postgresql" {
      driver = "docker"

      config {
             ports=["database"]

        image = "postgres"
      }
    volume_mount {
        volume = "mastodon"
        read_only = false
        destination = "/var/lib/postgresql"
    }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/mastodon" -}}
POSTGRES_USER=mastodon
POSTGRES_PASSWORD		= {{.POSTGRES_PASSWORD}}
{{- end -}}
EOF
     }

      resources {
        memory = 256
      }

      service {
        name = "postgres"
        port = "database"

             check {
                  type     = "http"
                  path    = "/"
                  interval = "60s"
                  timeout  = "10s"
        }
      }
    }

    task "redis" {
      driver = "docker"

      config {
             ports=["redis"]

        image = "redis"
      }

      resources {
        memory = 256
      }

      service {
        name = "redis"
        port = "redis"

             check {
                  type     = "tcp"
                  interval = "60s"
                  timeout  = "10s"
        }
      }
    }

  task "mastodon" {
      driver = "docker"

      config {
             ports=["http"]

        image = "lscr.io/linuxserver/mastodon:latest"
      }

  env {
    DB_HOST=NOMAD_HOST_IP_database
    DB_PORT=NOMAD_HOST_PORT_database
    DB_USER="mastodon" 
    DB_NAME="mastodon"
    REDIS_HOST=NOMAD_IP_redis
    REDIS_PORT=NOMAD_HOST_PORT_redis
    PUID=1000
    PGID=1000
    ES_ENABLED="false"
    VAPID_PRIVATE_KEY=""
    VAPID_PUBLIC_KEY=""
    SMTP_SERVER="mail.example.com"
    SMTP_PORT=25
    SMTP_LOGIN=""
    SMTP_PASSWORD=""
    SMTP_FROM_ADDRESS="notifications@example.com"
    S3_ENABLED="false"
    ES_HOST="es"
    ES_PORT="9200"
    ES_USER="elastic"
    ES_PASS="elastic"
    S3_BUCKET=""
    AWS_ACCESS_KEY_ID=""
    AWS_SECRET_ACCESS_KEY=""
    S3_ALIAS_HOST=""
    SIDEKIQ_ONLY="false"
    SIDEKIQ_QUEUE=""
    SIDEKIQ_DEFAULT="false"
    SIDEKIQ_THREADS="5"
    DB_POOL="5"
  }
      template {
        destination = "${NOMAD_SECRETS_DIR}/env.vars"
        env         = true
        change_mode = "restart"
        data        = <<EOF
{{- with nomadVar "nomad/jobs/mastodon" -}}
DB_PASS		= {{.POSTGRES_PASSWORD}}
TZ={{.TZ}}
OTP_SECRET={{.OTP_SECRET}}
SECRET_KEY_BASE={{.SECRET_KEY_BASE}}
LOCAL_DOMAIN={{.LOCAL_DOMAIN}}
WEB_DOMAIN={{.WEB_DOMAIN}}
{{- end -}}
EOF
     }

      resources {
        memory = 1024
      }

      service {
        name = "mastodon"
        port = "http"

             check {
                  type     = "tcp"
                  interval = "60s"
                  timeout  = "10s"
        }
      }
    }
  }
}
