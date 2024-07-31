s Puppet manifest configures Nginx to include a custom HTTP header "X-Served-By"
# with the hostname of the server Nginx is running on.

# Ensure the Nginx package is installed
package { 'nginx':
  ensure => installed,
}

# Ensure the Nginx service is running and enabled to start at boot
service { 'nginx':
  ensure     => running,
  enable     => true,
  subscribe  => File['/etc/nginx/sites-available/default'],
}

# Configure the Nginx default site to include the custom header
file { '/etc/nginx/sites-available/default':
  ensure  => file,
  content => template('nginx/default.erb'),
  notify  => Service['nginx'],
}

# Ensure the hostname is correctly set in the system
file_line { 'set_hostname':
  path => '/etc/hostname',
  line => $facts['hostname'],
  notify  => Exec['set_hostname'],
}

exec { 'set_hostname':
  command => "hostname ${facts['hostname']}",
  unless  => "test $(hostname) = ${facts['hostname']}",
  path    => '/usr/bin:/usr/sbin:/bin:/sbin',
}

# Create the Nginx template with the custom header
file { '/etc/puppetlabs/code/environments/production/modules/nginx/templates/default.erb':
  ensure  => file,
  content => '
server {
    listen 80 default_server;
    listen [::]:80 default_server;

    root /var/www/html;
    index index.html index.htm index.nginx-debian.html;

    server_name _;

    location / {
        try_files $uri $uri/ =404;
        add_header X-Served-By $hostname;
    }
}
',
}

# Ensure the directory for the templates exists
file { '/etc/puppetlabs/code/environments/production/modules/nginx/templates':
  ensure => directory,
}

# Create the template for the default site configuration
file { '/etc/puppetlabs/code/environments/production/modules/nginx/templates/default.erb':
  ensure  => file,
  content => template('nginx/default.erb'),
  notify  => Service['nginx'],
}
