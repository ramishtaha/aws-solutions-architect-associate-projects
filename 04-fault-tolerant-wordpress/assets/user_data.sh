#!/bin/bash -ex
# User Data Script for WordPress Installation on Amazon Linux 2023
# This script is designed to be idempotent and robust.
# It logs all output to /var/log/user-data.log for easy debugging.

# Redirect all output to a log file
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1

echo "Starting user data script execution..."

# Wait for network to be ready
echo "Waiting for network to be ready..."
for i in {1..30}; do
    if curl -s --head http://www.google.com | grep "200 OK" > /dev/null; then
        echo "Network is up."
        break
    fi
    echo "Waiting for network... attempt $i"
    sleep 2
done

# Update the system
echo "Updating system packages..."
yum update -y

# Install Apache web server
echo "Installing Apache (httpd)..."
yum install -y httpd

# Start and enable Apache
echo "Starting and enabling httpd service..."
systemctl start httpd
systemctl enable httpd
systemctl is-active --quiet httpd && echo "httpd is running." || (echo "httpd failed to start." && exit 1)

# Install PHP and required extensions for WordPress
echo "Installing PHP and extensions..."
yum install -y php php-cli php-pdo php-fpm php-json php-mysqlnd php-mbstring php-xml php-gd php-opcache php-curl

# Start and enable PHP-FPM
echo "Starting and enabling php-fpm service..."
systemctl start php-fpm
systemctl enable php-fpm
systemctl is-active --quiet php-fpm && echo "php-fpm is running." || (echo "php-fpm failed to start." && exit 1)

# Restart Apache to load PHP modules
echo "Restarting httpd to load PHP..."
systemctl restart httpd

# Check if WordPress is already installed
if [ -f /var/www/html/wp-config.php ]; then
    echo "WordPress is already installed. Skipping installation."
else
    echo "WordPress not found. Starting installation..."
    # Download and extract WordPress
    echo "Downloading and extracting WordPress..."
    cd /tmp
    wget https://wordpress.org/latest.tar.gz
    tar -xzf latest.tar.gz

    # Move WordPress files to Apache document root
    echo "Moving WordPress files to /var/www/html/..."
    # Clear the document root before copying files
    rm -rf /var/www/html/*
    cp -r wordpress/* /var/www/html/

    # Set proper permissions for WordPress (more secure)
    echo "Setting file permissions for WordPress..."
    chown -R apache:apache /var/www/html/
    find /var/www/html/ -type d -exec chmod 755 {} \;
    find /var/www/html/ -type f -exec chmod 644 {} \;

    # Create WordPress configuration file
    echo "Creating wp-config.php..."
    cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
    chown apache:apache /var/www/html/wp-config.php

    # Configure WordPress to connect to RDS database
    echo "Configuring database connection..."
    sed -i "s/database_name_here/wordpress/" /var/www/html/wp-config.php
    sed -i "s/username_here/admin/" /var/www/html/wp-config.php
    sed -i "s/password_here/REPLACE_WITH_DB_PASSWORD/" /var/www/html/wp-config.php
    sed -i "s/localhost/REPLACE_WITH_RDS_ENDPOINT/" /var/www/html/wp-config.php

    # Generate and insert WordPress security keys
    echo "Generating and inserting WordPress security salts..."
    SALT=$(curl -L https://api.wordpress.org/secret-key/1.1/salt/)
    # Use sed to replace the placeholder block with the new salts
    sed -i "/define('AUTH_KEY',         'put your unique phrase here');/c\\$SALT" /var/www/html/wp-config.php

    # Configure WordPress to use the ALB/ELB setup
    echo "Configuring for Load Balancer..."
    cat >> /var/www/html/wp-config.php << 'EOF'

if (isset($_SERVER['HTTP_X_FORWARDED_PROTO']) && $_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    $_SERVER['HTTPS'] = 'on';
}
EOF
fi

# Create a simple health check page for the ALB
echo "Creating health check page..."
cat > /var/www/html/health.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Health Check</title>
</head>
<body>
    <h1>Server is healthy</h1>
</body>
</html>
EOF

# Set up log rotation for httpd
echo "Setting up log rotation..."
cat > /etc/logrotate.d/httpd << 'EOF'
/var/log/httpd/*log {
    daily
    missingok
    rotate 14
    compress
    delaycompress
    notifempty
    create 644 root root
    sharedscripts
    postrotate
        /bin/systemctl reload httpd.service > /dev/null 2>/dev/null || true
    endscript
}
EOF

# Install CloudWatch agent for monitoring (optional but recommended)
echo "Installing CloudWatch agent..."
yum install -y amazon-cloudwatch-agent

# Final restart of services to apply all changes
echo "Final restart of httpd and php-fpm..."
systemctl restart httpd
systemctl restart php-fpm

echo "User data script execution finished successfully."

# Log completion
echo "WordPress installation completed at $(date)" >> /var/log/wordpress-install.log
