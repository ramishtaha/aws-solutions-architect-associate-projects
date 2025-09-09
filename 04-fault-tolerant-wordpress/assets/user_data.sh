#!/bin/bash
# User Data Script for WordPress Installation on Amazon Linux 2023
# This script installs Apache, PHP, WordPress and configures the connection to RDS

# Update the system
yum update -y

# Install Apache web server
yum install -y httpd

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install PHP and required extensions for WordPress
yum install -y php php-cli php-pdo php-fpm php-json php-mysqlnd php-mbstring php-xml php-gd php-opcache php-curl

# Restart Apache to load PHP modules
systemctl restart httpd

# Download and extract WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz

# Move WordPress files to Apache document root
cp -r wordpress/* /var/www/html/

# Set proper permissions for WordPress
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# Create WordPress configuration file
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Configure WordPress to connect to RDS database
# Note: Replace these placeholders with actual values during deployment
# DB_NAME: wordpress
# DB_USER: admin
# DB_PASSWORD: your-secure-password
# DB_HOST: your-rds-endpoint

sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
sed -i "s/username_here/admin/" /var/www/html/wp-config.php
sed -i "s/password_here/YourSecurePassword123!/" /var/www/html/wp-config.php
sed -i "s/localhost/REPLACE_WITH_RDS_ENDPOINT/" /var/www/html/wp-config.php

# Generate WordPress security keys
curl -s https://api.wordpress.org/secret-key/1.1/salt/ >> /tmp/wp-keys.txt

# Add security keys to wp-config.php (this is a simplified approach)
# In production, you would want to handle this more securely
cat >> /var/www/html/wp-config.php << 'EOF'

/* Custom WordPress Security Keys */
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
EOF

# Configure WordPress to use the ALB/ELB setup
cat >> /var/www/html/wp-config.php << 'EOF'

/* SSL and Load Balancer Configuration */
if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}

/* That's all, stop editing! Happy publishing. */
EOF

# Create a simple health check page for the ALB
cat > /var/www/html/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>Server is healthy</h1>
    <p>Timestamp: $(date)</p>
</body>
</html>
EOF

# Set up log rotation for WordPress
cat > /etc/logrotate.d/wordpress << 'EOF'
/var/log/httpd/*log {
    daily
    missingok
    rotate 52
    compress
    delaycompress
    notifempty
    create 644 apache apache
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>&1 || true
    endscript
}
EOF

# Install CloudWatch agent for monitoring (optional but recommended)
yum install -y amazon-cloudwatch-agent

# Create a startup script to ensure services are running
cat > /etc/rc.local << 'EOF'
#!/bin/bash
systemctl start httpd
systemctl start php-fpm
EOF

chmod +x /etc/rc.local

# Final restart of services
systemctl restart httpd
systemctl restart php-fpm

# Log completion
echo "WordPress installation completed at $(date)" >> /var/log/wordpress-install.log
