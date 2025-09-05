#!/bin/bash
# Database Connectivity Test Script
# This script tests connectivity between EC2 instances and RDS database

# Configuration (update these with your actual values)
DB_HOST="wordpress-db.xxxxxxxxxx.us-east-1.rds.amazonaws.com"
DB_USER="admin"
DB_PASS="WordPress2024!SecurePass"
DB_NAME="wordpress"
DB_PORT="3306"

echo "🔍 Testing WordPress Database Connectivity"
echo "==========================================="

# Function to test basic connectivity
test_connectivity() {
    echo "1. Testing network connectivity to database..."
    
    # Test if port is reachable
    if command -v nc >/dev/null 2>&1; then
        if nc -z $DB_HOST $DB_PORT; then
            echo "✅ Network connectivity: Port $DB_PORT is reachable"
        else
            echo "❌ Network connectivity: Port $DB_PORT is NOT reachable"
            echo "   Check security groups and network ACLs"
            return 1
        fi
    else
        echo "⚠️  netcat (nc) not available, skipping port test"
    fi
}

# Function to test DNS resolution
test_dns() {
    echo "2. Testing DNS resolution..."
    
    if nslookup $DB_HOST >/dev/null 2>&1; then
        RESOLVED_IP=$(nslookup $DB_HOST | grep -A1 "Name:" | tail -1 | awk '{print $2}')
        echo "✅ DNS resolution: $DB_HOST resolves to $RESOLVED_IP"
    else
        echo "❌ DNS resolution: Cannot resolve $DB_HOST"
        return 1
    fi
}

# Function to test MySQL connectivity
test_mysql_connection() {
    echo "3. Testing MySQL database connection..."
    
    # Check if MySQL client is installed
    if ! command -v mysql >/dev/null 2>&1; then
        echo "❌ MySQL client not installed"
        echo "   Install with: sudo yum install mysql"
        return 1
    fi
    
    # Test basic connection
    if mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "SELECT 1;" >/dev/null 2>&1; then
        echo "✅ MySQL connection: Successfully connected to database"
    else
        echo "❌ MySQL connection: Failed to connect"
        echo "   Check username, password, and security group rules"
        return 1
    fi
}

# Function to test WordPress database
test_wordpress_database() {
    echo "4. Testing WordPress database access..."
    
    # Test if WordPress database exists and is accessible
    RESULT=$(mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "USE $DB_NAME; SELECT COUNT(*) as table_count FROM information_schema.tables WHERE table_schema='$DB_NAME';" 2>/dev/null | tail -1)
    
    if [ $? -eq 0 ]; then
        echo "✅ WordPress database: Accessible (contains $RESULT tables)"
        
        # Check if WordPress is installed
        WP_TABLES=$(mysql -h $DB_HOST -P $DB_PORT -u $DB_USER -p$DB_PASS -e "USE $DB_NAME; SHOW TABLES LIKE 'wp_%';" 2>/dev/null | wc -l)
        if [ $WP_TABLES -gt 1 ]; then
            echo "✅ WordPress installation: Found $((WP_TABLES-1)) WordPress tables"
        else
            echo "⚠️  WordPress installation: No WordPress tables found (fresh database)"
        fi
    else
        echo "❌ WordPress database: Cannot access $DB_NAME database"
        return 1
    fi
}

# Function to test from WordPress perspective
test_wordpress_config() {
    echo "5. Testing WordPress configuration..."
    
    # Check if wp-config.php exists
    if [ -f "/var/www/html/wp-config.php" ]; then
        echo "✅ WordPress config: wp-config.php found"
        
        # Extract database configuration from wp-config.php
        DB_NAME_WP=$(grep "DB_NAME" /var/www/html/wp-config.php | cut -d"'" -f4)
        DB_USER_WP=$(grep "DB_USER" /var/www/html/wp-config.php | cut -d"'" -f4)
        DB_HOST_WP=$(grep "DB_HOST" /var/www/html/wp-config.php | cut -d"'" -f4)
        
        echo "   WordPress DB Name: $DB_NAME_WP"
        echo "   WordPress DB User: $DB_USER_WP"
        echo "   WordPress DB Host: $DB_HOST_WP"
        
        if [ "$DB_HOST_WP" = "$DB_HOST" ]; then
            echo "✅ WordPress config: Database host matches"
        else
            echo "⚠️  WordPress config: Database host mismatch"
            echo "   Expected: $DB_HOST"
            echo "   Found: $DB_HOST_WP"
        fi
    else
        echo "⚠️  WordPress config: wp-config.php not found"
        echo "   WordPress may not be configured yet"
    fi
}

# Function to test web server connectivity
test_web_server() {
    echo "6. Testing web server status..."
    
    # Check if Apache is running
    if systemctl is-active --quiet httpd; then
        echo "✅ Web server: Apache is running"
    else
        echo "❌ Web server: Apache is not running"
        echo "   Start with: sudo systemctl start httpd"
    fi
    
    # Check if WordPress is accessible locally
    if curl -s -o /dev/null -w "%{http_code}" http://localhost | grep -q "200\|302\|301"; then
        echo "✅ Web server: WordPress responds locally"
    else
        echo "⚠️  Web server: WordPress not responding locally"
    fi
}

# Function to generate troubleshooting report
generate_report() {
    echo ""
    echo "📊 System Information Report"
    echo "============================"
    echo "Instance ID: $(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo 'Not available')"
    echo "Availability Zone: $(curl -s http://169.254.169.254/latest/meta-data/placement/availability-zone 2>/dev/null || echo 'Not available')"
    echo "Private IP: $(curl -s http://169.254.169.254/latest/meta-data/local-ipv4 2>/dev/null || echo 'Not available')"
    echo "Public IP: $(curl -s http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo 'Not available')"
    echo ""
    echo "Security Groups:"
    curl -s http://169.254.169.254/latest/meta-data/security-groups 2>/dev/null || echo "Not available"
    echo ""
    echo "Network Interfaces:"
    ip addr show | grep -E "(inet |mtu )" | grep -v "127.0.0.1"
    echo ""
    echo "Route Table:"
    route -n
}

# Main execution
echo "Starting connectivity tests..."
echo "Database Host: $DB_HOST"
echo "Database Port: $DB_PORT"
echo "Database Name: $DB_NAME"
echo "Database User: $DB_USER"
echo ""

# Run all tests
FAILED_TESTS=0

test_connectivity || ((FAILED_TESTS++))
echo ""

test_dns || ((FAILED_TESTS++))
echo ""

test_mysql_connection || ((FAILED_TESTS++))
echo ""

test_wordpress_database || ((FAILED_TESTS++))
echo ""

test_wordpress_config || ((FAILED_TESTS++))
echo ""

test_web_server || ((FAILED_TESTS++))
echo ""

# Final summary
echo "🏁 Test Summary"
echo "==============="
if [ $FAILED_TESTS -eq 0 ]; then
    echo "✅ All tests passed! WordPress should be working correctly."
else
    echo "❌ $FAILED_TESTS test(s) failed. Review the issues above."
    echo ""
    echo "📋 Common Solutions:"
    echo "   • Security Groups: Ensure DB security group allows port 3306 from web servers"
    echo "   • Network ACLs: Check if custom NACLs are blocking traffic"
    echo "   • RDS Status: Verify RDS instance is 'available' in AWS Console"
    echo "   • DNS Resolution: Ensure VPC has DNS resolution enabled"
    echo "   • Database Credentials: Verify username/password are correct"
    echo ""
    generate_report
fi

echo ""
echo "💡 Additional Commands:"
echo "   • View Apache logs: sudo tail -f /var/log/httpd/error_log"
echo "   • View WordPress logs: sudo tail -f /var/log/httpd/access_log"
echo "   • Test specific connection: mysql -h $DB_HOST -u $DB_USER -p"
echo "   • Check security groups: aws ec2 describe-security-groups --region us-east-1"
