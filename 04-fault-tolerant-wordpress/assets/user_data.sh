#!/bin/bash
# user_data.sh - EC2 User Data to bootstrap a LAMP + WordPress server on Amazon Linux 2
# Idempotent and safe to re-run; suitable for use in a Launch Template/Auto Scaling Group.
# Reads DB connection details from environment variables you pass via the Launch Template or SSM Parameter Store.
# Required env vars (set in Launch Template > Advanced details > User data or via /etc/environment):
#   WORDPRESS_DB_NAME
#   WORDPRESS_DB_USER
#   WORDPRESS_DB_PASSWORD
#   WORDPRESS_DB_HOST  (RDS endpoint, e.g., mydb.abc123.us-east-1.rds.amazonaws.com)

set -euxo pipefail

LOG_FILE=/var/log/user-data-wordpress.log
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] Starting bootstrap at $(date)"

#--------------------------
# System updates and basics
#--------------------------
yum clean all -y || true
yum update -y

#--------------------------
# Install Apache, PHP, MariaDB client, wget, unzip
#--------------------------
yum install -y httpd wget unzip curl
# Amazon Linux 2 provides php via amazon-linux-extras
amazon-linux-extras enable php8.2 || amazon-linux-extras enable php8.1 || true
yum clean metadata -y || true
yum install -y php php-mysqlnd php-fpm php-json php-mbstring php-xml mariadb105

# Ensure services
systemctl enable httpd
systemctl start httpd

#--------------------------
# Configure Apache for WordPress
#--------------------------
sed -i 's/^#ServerName.*/ServerName localhost/' /etc/httpd/conf/httpd.conf || true
setsebool -P httpd_can_network_connect 1 || true

usermod -a -G apache ec2-user || true
chown -R ec2-user:apache /var/www
chmod 2775 /var/www
find /var/www -type d -exec chmod 2775 {} \;
find /var/www -type f -exec chmod 0664 {} \;

#--------------------------
# Fetch WordPress
#--------------------------
WP_DIR=/var/www/html
mkdir -p "$WP_DIR"
cd /tmp
WP_VERSION="latest"
if [ ! -f "/tmp/wordpress-$WP_VERSION.tar.gz" ]; then
  curl -fsSL -o "/tmp/wordpress-$WP_VERSION.tar.gz" "https://wordpress.org/${WP_VERSION}.tar.gz"
fi

tar -xzf "/tmp/wordpress-$WP_VERSION.tar.gz"
rsync -a --delete /tmp/wordpress/ "$WP_DIR/"

# Create uploads dir and set permissions
mkdir -p "$WP_DIR/wp-content/uploads"
chown -R apache:apache "$WP_DIR"
find "$WP_DIR" -type d -exec chmod 755 {} \;
find "$WP_DIR" -type f -exec chmod 644 {} \;

#--------------------------
# Configure wp-config.php
#--------------------------
cd "$WP_DIR"
if [ ! -f wp-config.php ]; then
  cp wp-config-sample.php wp-config.php
fi

# Apply DB settings from env or fallback placeholders
: "${WORDPRESS_DB_NAME:=wordpress}"
: "${WORDPRESS_DB_USER:=wpuser}"
: "${WORDPRESS_DB_PASSWORD:=ChangeMe123!}"
: "${WORDPRESS_DB_HOST:=YOUR-RDS-ENDPOINT.amazonaws.com}"

# Update wp-config.php safely
php -r "
$cfg = file_get_contents('wp-config.php');
$cfg = preg_replace('/define\(\'DB_NAME\',\s*'[^']*'\);/','define(\'DB_NAME\', '\''.$_SERVER['WORDPRESS_DB_NAME'].'\');',$cfg);
$cfg = preg_replace('/define\(\'DB_USER\',\s*'[^']*'\);/','define(\'DB_USER\', '\''.$_SERVER['WORDPRESS_DB_USER'].'\');',$cfg);
$cfg = preg_replace('/define\(\'DB_PASSWORD\',\s*'[^']*'\);/','define(\'DB_PASSWORD\', '\''.$_SERVER['WORDPRESS_DB_PASSWORD'].'\');',$cfg);
$cfg = preg_replace('/define\(\'DB_HOST\',\s*'[^']*'\);/','define(\'DB_HOST\', '\''.$_SERVER['WORDPRESS_DB_HOST'].'\');',$cfg);
file_put_contents('wp-config.php',$cfg);
" || {
  # Fallback to sed if php -r fails
  sed -i "s/database_name_here/${WORDPRESS_DB_NAME}/" wp-config.php
  sed -i "s/username_here/${WORDPRESS_DB_USER}/" wp-config.php
  sed -i "s/password_here/${WORDPRESS_DB_PASSWORD}/" wp-config.php
  sed -i "s/localhost/${WORDPRESS_DB_HOST}/" wp-config.php
}

# Add unique salts
PHP_SALTS=$(curl -fsSL https://api.wordpress.org/secret-key/1.1/salt/ || true)
if [ -n "$PHP_SALTS" ]; then
  awk -v r="$PHP_SALTS" 'BEGIN{print r}' > /tmp/wp-salts.php
  php -r "
  $cfg = file_get_contents('wp-config.php');
  $cfg = preg_replace('/(?s)define\(\'AUTH_KEY\'.*?define\(\'NONCE_SALT\'.*?;\n/','', $cfg);
  file_put_contents('wp-config.php', $cfg);
  "
  sed -i "/#@-/r /tmp/wp-salts.php" wp-config.php || true
fi

# Allow direct filesystem writes for plugin/theme install (common in ephemeral instances)
grep -q "FS_METHOD" wp-config.php || echo "define('FS_METHOD','direct');" >> wp-config.php

# Basic health page
cat > "$WP_DIR/health.html" << 'EOF'
OK
EOF

# Restart Apache to pick up changes
systemctl restart httpd

#--------------------------
# Optional: Create a simple index.html redirect if needed
#--------------------------
if [ ! -f "$WP_DIR/index.php" ] && [ -f "$WP_DIR/index.html" ]; then
  # No action; WordPress provides index.php
  true
fi

echo "[INFO] Bootstrap completed at $(date)"
