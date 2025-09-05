#!/bin/bash
# WordPress Installation User Data Script
# This script installs and configures WordPress on Amazon Linux 2023

# Update system packages
yum update -y

# Install Apache web server
yum install -y httpd

# Install PHP 8.1 and required extensions
yum install -y php8.1 php8.1-cli php8.1-common php8.1-curl php8.1-gd php8.1-json php8.1-mbstring php8.1-mysql php8.1-xml php8.1-zip

# Start and enable Apache
systemctl start httpd
systemctl enable httpd

# Install MySQL client for database connectivity testing
yum install -y mysql

# Set proper permissions for Apache
usermod -a -G apache ec2-user
chown -R apache:apache /var/www
chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

# Download and install WordPress
cd /tmp
wget https://wordpress.org/latest.tar.gz
tar -xzf latest.tar.gz
cp -R wordpress/* /var/www/html/

# Set WordPress permissions
chown -R apache:apache /var/www/html/
chmod -R 755 /var/www/html/

# Remove default Apache index page
rm -f /var/www/html/index.html

# Create WordPress configuration file
cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php

# Note: Database details will be configured manually during WordPress setup
# This is intentional for learning purposes - students will enter DB details through web interface

# Configure PHP settings for WordPress
cat >> /etc/php.ini << 'EOF'
upload_max_filesize = 64M
post_max_size = 64M
max_execution_time = 300
memory_limit = 256M
EOF

# Create a simple health check page for ALB
cat > /var/www/html/health.php << 'EOF'
<?php
// Simple health check for Application Load Balancer
$status = "healthy";
$timestamp = date('Y-m-d H:i:s');

// Check if we can write to uploads directory
$uploads_dir = '/var/www/html/wp-content/uploads';
if (!is_writable($uploads_dir)) {
    $status = "unhealthy";
}

// Return JSON response
header('Content-Type: application/json');
echo json_encode([
    'status' => $status,
    'timestamp' => $timestamp,
    'server' => gethostname()
]);
?>
EOF

# Restart Apache to apply all changes
systemctl restart httpd

# Install AWS CLI for potential future automation
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
yum install -y unzip
unzip awscliv2.zip
sudo ./aws/install

# Create a startup script for any additional configuration
cat > /home/ec2-user/configure-wordpress.sh << 'EOF'
#!/bin/bash
# Additional WordPress configuration script
# Run this after RDS database is ready

echo "WordPress installation completed!"
echo "Access your site via the Application Load Balancer DNS name"
echo "Complete the WordPress setup through the web interface"
echo ""
echo "Database configuration:"
echo "- Database Name: wordpress"
echo "- Username: admin"
echo "- Password: [Use password from db-config.txt]"
echo "- Database Host: [Use RDS endpoint]"
echo ""
echo "Health check URL: http://[ALB-DNS]/health.php"
EOF

chmod +x /home/ec2-user/configure-wordpress.sh

# Log completion
echo "WordPress installation script completed at $(date)" >> /var/log/wordpress-install.log

# Signal that the instance is ready
/opt/aws/bin/cfn-signal -e $? --stack ${AWS::StackName} --resource AutoScalingGroup --region ${AWS::Region} 2>/dev/null || echo "CloudFormation signal not available"
