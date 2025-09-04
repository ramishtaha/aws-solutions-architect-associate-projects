#!/bin/bash

# WordPress LAMP Stack Installation and Configuration Script
# This script automates the setup of Apache, PHP, MySQL client, and WordPress
# on Amazon Linux 2023 instances for a fault-tolerant deployment

# Enable logging for troubleshooting
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "Starting WordPress installation at $(date)"

# Update system packages
echo "Updating system packages..."
dnf update -y

# Install Apache web server
echo "Installing Apache web server..."
dnf install -y httpd
systemctl start httpd
systemctl enable httpd

# Install PHP 8.1 and required modules for WordPress
echo "Installing PHP and required modules..."
dnf install -y php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-gd php8.1-mbstring php8.1-mysql php8.1-xml php8.1-zip php8.1-json php8.1-opcache

# Install MySQL client for database connectivity testing
echo "Installing MySQL client..."
dnf install -y mysql

# Configure PHP for WordPress
echo "Configuring PHP settings..."
# Increase memory limit and file upload sizes for WordPress
sed -i 's/memory_limit = .*/memory_limit = 256M/' /etc/php.ini
sed -i 's/upload_max_filesize = .*/upload_max_filesize = 64M/' /etc/php.ini
sed -i 's/post_max_size = .*/post_max_size = 64M/' /etc/php.ini
sed -i 's/max_execution_time = .*/max_execution_time = 300/' /etc/php.ini

# Download WordPress
echo "Downloading WordPress..."
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar xzf latest.tar.gz

# Move WordPress files to web root
echo "Installing WordPress files..."
cp -R wordpress/* /var/www/html/
rm -rf wordpress latest.tar.gz

# Set proper ownership and permissions
echo "Setting file permissions..."
chown -R apache:apache /var/www/html/
find /var/www/html/ -type d -exec chmod 755 {} \;
find /var/www/html/ -type f -exec chmod 644 {} \;

# Remove default Apache index.html to allow WordPress index.php to load
rm -f /var/www/html/index.html

# Create WordPress configuration file
echo "Configuring WordPress database connection..."
cd /var/www/html

# IMPORTANT: Replace these values with your actual RDS endpoint and credentials
# You must update these before launching instances!
DB_HOST="YOUR_RDS_ENDPOINT_HERE"  # e.g., wordpress-db.cluster-abc123.us-east-1.rds.amazonaws.com
DB_NAME="wordpressdb"
DB_USER="admin"
DB_PASSWORD="YOUR_DB_PASSWORD_HERE"  # Replace with your actual password

# Generate WordPress salts for security
echo "Generating WordPress security salts..."
SALT=$(curl -s https://api.wordpress.org/secret-key/1.1/salt/)

# Create wp-config.php from sample
cp wp-config-sample.php wp-config.php

# Configure database connection in wp-config.php
sed -i "s/database_name_here/$DB_NAME/" wp-config.php
sed -i "s/username_here/$DB_USER/" wp-config.php
sed -i "s/password_here/$DB_PASSWORD/" wp-config.php
sed -i "s/localhost/$DB_HOST/" wp-config.php

# Add security salts to wp-config.php (replace the placeholder lines)
# This is a simplified approach - in production, you'd use the actual API response
cat > /tmp/wp-config-salt.php << 'EOF'
define('AUTH_KEY',         'put your unique phrase here');
define('SECURE_AUTH_KEY',  'put your unique phrase here');
define('LOGGED_IN_KEY',    'put your unique phrase here');
define('NONCE_KEY',        'put your unique phrase here');
define('AUTH_SALT',        'put your unique phrase here');
define('SECURE_AUTH_SALT', 'put your unique phrase here');
define('LOGGED_IN_SALT',   'put your unique phrase here');
define('NONCE_SALT',       'put your unique phrase here');
EOF

# Replace the placeholder salts with real ones from WordPress API
curl -s https://api.wordpress.org/secret-key/1.1/salt/ > /tmp/wp-salts.txt
sed -i '/AUTH_KEY/,/NONCE_SALT/c\
' wp-config.php

# Insert the new salts
sed -i '/<?php/r /tmp/wp-salts.txt' wp-config.php

# Add WordPress performance and security configurations
cat >> wp-config.php << 'EOF'

/* WordPress Performance and Security Settings */
define('WP_CACHE', true);
define('COMPRESS_CSS', true);
define('COMPRESS_SCRIPTS', true);
define('CONCATENATE_SCRIPTS', true);
define('ENFORCE_GZIP', true);

/* Disable file editing from WordPress admin */
define('DISALLOW_FILE_EDIT', true);

/* Auto-update settings */
define('WP_AUTO_UPDATE_CORE', true);

/* Memory limit */
define('WP_MEMORY_LIMIT', '256M');

/* Database repair */
define('WP_ALLOW_REPAIR', true);
EOF

# Set final permissions on wp-config.php
chmod 600 wp-config.php
chown apache:apache wp-config.php

# Configure Apache virtual host for WordPress
echo "Configuring Apache virtual host..."
cat > /etc/httpd/conf.d/wordpress.conf << 'EOF'
<VirtualHost *:80>
    DocumentRoot /var/www/html
    ServerName localhost
    
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
        
        # Enable rewrite engine for WordPress permalinks
        RewriteEngine On
        
        # WordPress standard rules
        RewriteBase /
        RewriteRule ^index\.php$ - [L]
        RewriteCond %{REQUEST_FILENAME} !-f
        RewriteCond %{REQUEST_FILENAME} !-d
        RewriteRule . /index.php [L]
    </Directory>
    
    # Security headers
    Header always set X-Content-Type-Options nosniff
    Header always set X-Frame-Options DENY
    Header always set X-XSS-Protection "1; mode=block"
    Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
    Header always set Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; style-src 'self' 'unsafe-inline';"
    
    # Logging
    ErrorLog /var/log/httpd/wordpress_error.log
    CustomLog /var/log/httpd/wordpress_access.log combined
</VirtualHost>
EOF

# Enable mod_rewrite and mod_headers for WordPress and security
echo "Enabling Apache modules..."
echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/httpd/conf/httpd.conf
echo "LoadModule headers_module modules/mod_headers.so" >> /etc/httpd/conf/httpd.conf

# Create .htaccess file for WordPress permalinks
echo "Creating .htaccess file..."
cat > /var/www/html/.htaccess << 'EOF'
# BEGIN WordPress
<IfModule mod_rewrite.c>
RewriteEngine On
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
</IfModule>
# END WordPress

# Security settings
<Files wp-config.php>
order allow,deny
deny from all
</Files>

# Disable directory browsing
Options -Indexes

# Prevent access to sensitive files
<FilesMatch "\.(htaccess|htpasswd|ini|log|sh|inc|bak)$">
Order Allow,Deny
Deny from all
</FilesMatch>
EOF

chown apache:apache /var/www/html/.htaccess
chmod 644 /var/www/html/.htaccess

# Install and configure fail2ban for additional security
echo "Installing fail2ban for security..."
dnf install -y fail2ban
systemctl start fail2ban
systemctl enable fail2ban

# Configure basic fail2ban rules
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3

[sshd]
enabled = true

[apache-auth]
enabled = true

[apache-badbots]
enabled = true

[apache-noscript]
enabled = true

[apache-overflows]
enabled = true
EOF

systemctl restart fail2ban

# Install CloudWatch agent for monitoring
echo "Installing CloudWatch agent..."
dnf install -y amazon-cloudwatch-agent

# Create CloudWatch agent configuration
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
    "agent": {
        "metrics_collection_interval": 60,
        "run_as_user": "cwagent"
    },
    "metrics": {
        "namespace": "WordPress/EC2",
        "metrics_collected": {
            "cpu": {
                "measurement": [
                    "cpu_usage_idle",
                    "cpu_usage_iowait",
                    "cpu_usage_user",
                    "cpu_usage_system"
                ],
                "metrics_collection_interval": 60
            },
            "disk": {
                "measurement": [
                    "used_percent"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "diskio": {
                "measurement": [
                    "io_time"
                ],
                "metrics_collection_interval": 60,
                "resources": [
                    "*"
                ]
            },
            "mem": {
                "measurement": [
                    "mem_used_percent"
                ],
                "metrics_collection_interval": 60
            }
        }
    },
    "logs": {
        "logs_collected": {
            "files": {
                "collect_list": [
                    {
                        "file_path": "/var/log/httpd/wordpress_error.log",
                        "log_group_name": "wordpress-apache-error",
                        "log_stream_name": "{instance_id}"
                    },
                    {
                        "file_path": "/var/log/httpd/wordpress_access.log",
                        "log_group_name": "wordpress-apache-access",
                        "log_stream_name": "{instance_id}"
                    }
                ]
            }
        }
    }
}
EOF

# Start CloudWatch agent
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s

# Create a health check endpoint for the load balancer
echo "Creating health check endpoint..."
cat > /var/www/html/health.php << 'EOF'
<?php
// Simple health check for load balancer
// Returns HTTP 200 if WordPress can connect to database

header('Content-Type: application/json');

// Check if wp-config.php exists and can be loaded
if (!file_exists(__DIR__ . '/wp-config.php')) {
    http_response_code(503);
    echo json_encode(['status' => 'error', 'message' => 'WordPress not configured']);
    exit;
}

// Load WordPress configuration
require_once(__DIR__ . '/wp-config.php');

// Test database connection
$connection = @mysqli_connect(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);

if (!$connection) {
    http_response_code(503);
    echo json_encode(['status' => 'error', 'message' => 'Database connection failed']);
    exit;
}

mysqli_close($connection);

// All checks passed
http_response_code(200);
echo json_encode([
    'status' => 'healthy',
    'timestamp' => date('c'),
    'server' => gethostname()
]);
?>
EOF

chown apache:apache /var/www/html/health.php
chmod 644 /var/www/html/health.php

# Restart Apache to apply all configurations
echo "Restarting Apache web server..."
systemctl restart httpd

# Test database connectivity
echo "Testing database connectivity..."
if command -v mysql &> /dev/null; then
    # Note: This will fail until you update the DB_HOST and DB_PASSWORD variables above
    mysql -h "$DB_HOST" -u "$DB_USER" -p"$DB_PASSWORD" -e "SELECT 1;" 2>/dev/null
    if [ $? -eq 0 ]; then
        echo "Database connection successful"
    else
        echo "Database connection failed - please verify RDS endpoint and credentials"
    fi
fi

# Create a startup script for post-reboot configuration
cat > /etc/rc.local << 'EOF'
#!/bin/bash
# Ensure services start after reboot
systemctl start httpd
systemctl start fail2ban
/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -a fetch-config -m ec2 -c file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json -s
exit 0
EOF

chmod +x /etc/rc.local

# Create WordPress CLI download for future management
echo "Installing WP-CLI for command line management..."
curl -O https://raw.githubusercontent.com/wp-cli/wp-cli/v2.8.1/phar/wp-cli.phar
chmod +x wp-cli.phar
mv wp-cli.phar /usr/local/bin/wp

# Set up log rotation for WordPress logs
echo "Configuring log rotation..."
cat > /etc/logrotate.d/wordpress << 'EOF'
/var/log/httpd/wordpress_*.log {
    daily
    missingok
    rotate 14
    compress
    notifempty
    create 644 apache apache
    postrotate
        systemctl reload httpd > /dev/null 2>&1 || true
    endscript
}
EOF

# Final status report
echo "WordPress installation completed at $(date)"
echo "====== INSTALLATION SUMMARY ======"
echo "✓ Apache web server installed and configured"
echo "✓ PHP 8.1 with WordPress modules installed"
echo "✓ MySQL client installed"
echo "✓ WordPress downloaded and configured"
echo "✓ Security configurations applied"
echo "✓ CloudWatch monitoring configured"
echo "✓ Health check endpoint created at /health.php"
echo "✓ WP-CLI installed for command line management"
echo ""
echo "⚠️  IMPORTANT NEXT STEPS:"
echo "1. Update DB_HOST and DB_PASSWORD variables in this script"
echo "2. Recreate launch template with updated user data"
echo "3. Access ALB DNS name to complete WordPress setup"
echo "4. Database connection will fail until RDS endpoint is configured"
echo ""
echo "WordPress should be accessible via the Application Load Balancer"
echo "Check /var/log/user-data.log for detailed installation logs"

# Signal completion to CloudFormation/Auto Scaling (if used)
# This helps with health checks and deployment verification
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} 2>/dev/null || echo "CloudFormation signaling not available"
