# 7-puppet_install_nginx_web_server.pp
# Puppet manifest to install and configure Nginx with a custom root page and 301 redirect

package { 'nginx':
  ensure => installed,
}

service { 'nginx':
  ensure     => running,
  enable     => true,
  require    => Package['nginx'],
}

file { '/var/www/html/index.html':
  ensure  => file,
  content => '<html>
  <head><title>Hello World</title></head>
  <body>Hello World!</body>
  </html>',
  require => Package['nginx'],
}

file { '/etc/nginx/sites-available/default':
  ensure  => file,
  content => '
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    root /var/www/html;

    location / {
        try_files $uri $uri/ =404;
    }

    location /redirect_me {
        return 301 https://www.example.com$request_uri;
    }
}',
  require => Package['nginx'],
  notify  => Service['nginx'],  
}

exec { 'nginx-reload':
  command     => '/usr/sbin/nginx -s reload',
  refreshonly => true,
  subscribe   => File['/etc/nginx/sites-available/default'],
  require     => Service['nginx'],
}
