listen {
  port = 4040
}

namespace "nginx" {
  source = {
    files = [
      "/var/log/nginx/access.log"
    ]
  }

#      format = "$remote_addr - [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\" \"$http_x_forwarded_for\" \"$request_length\" \"$upstream_response_time\" \"$request_time\""
#      format = "$remote_addr -$remote_user- [$time_local] $request_method \"$request_uri\" $status"
      format = "$remote_addr -$remote_user- [$time_local] \"$request\" $status $body_bytes_sent \"$http_referer\" \"$http_user_agent\""

  labels {
    app = "default"
  }
}

