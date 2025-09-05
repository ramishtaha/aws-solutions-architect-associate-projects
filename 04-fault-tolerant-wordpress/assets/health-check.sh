#!/bin/bash
# Health Check Script for WordPress Instances
# This script performs comprehensive health checks for WordPress instances in ALB

# Configuration
WORDPRESS_PATH="/var/www/html"
LOG_FILE="/var/log/wordpress-health.log"
MAX_LOG_SIZE=10485760  # 10MB

# Function to log messages
log_message() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a $LOG_FILE
}

# Function to rotate log file if it gets too large
rotate_log() {
    if [ -f "$LOG_FILE" ] && [ $(stat -c%s "$LOG_FILE") -gt $MAX_LOG_SIZE ]; then
        mv "$LOG_FILE" "$LOG_FILE.old"
        touch "$LOG_FILE"
        log_message "INFO" "Log file rotated"
    fi
}

# Function to check Apache/httpd status
check_web_server() {
    if systemctl is-active --quiet httpd; then
        log_message "OK" "Apache web server is running"
        return 0
    else
        log_message "ERROR" "Apache web server is not running"
        # Attempt to restart Apache
        log_message "INFO" "Attempting to restart Apache"
        if systemctl restart httpd; then
            log_message "OK" "Apache successfully restarted"
            return 0
        else
            log_message "ERROR" "Failed to restart Apache"
            return 1
        fi
    fi
}

# Function to check disk space
check_disk_space() {
    local usage=$(df / | awk 'NR==2 {print $5}' | sed 's/%//')
    local threshold=90
    
    if [ $usage -lt $threshold ]; then
        log_message "OK" "Disk usage is $usage% (below $threshold% threshold)"
        return 0
    else
        log_message "WARNING" "Disk usage is $usage% (above $threshold% threshold)"
        return 1
    fi
}

# Function to check memory usage
check_memory() {
    local mem_info=$(free | grep Mem)
    local total=$(echo $mem_info | awk '{print $2}')
    local used=$(echo $mem_info | awk '{print $3}')
    local usage=$((used * 100 / total))
    local threshold=90
    
    if [ $usage -lt $threshold ]; then
        log_message "OK" "Memory usage is $usage% (below $threshold% threshold)"
        return 0
    else
        log_message "WARNING" "Memory usage is $usage% (above $threshold% threshold)"
        return 1
    fi
}

# Function to check WordPress files
check_wordpress_files() {
    local critical_files=(
        "$WORDPRESS_PATH/index.php"
        "$WORDPRESS_PATH/wp-config.php"
        "$WORDPRESS_PATH/wp-load.php"
        "$WORDPRESS_PATH/wp-settings.php"
    )
    
    local missing_files=0
    
    for file in "${critical_files[@]}"; do
        if [ -f "$file" ]; then
            log_message "OK" "WordPress file exists: $file"
        else
            log_message "ERROR" "WordPress file missing: $file"
            ((missing_files++))
        fi
    done
    
    if [ $missing_files -eq 0 ]; then
        return 0
    else
        log_message "ERROR" "$missing_files critical WordPress files are missing"
        return 1
    fi
}

# Function to check WordPress permissions
check_wordpress_permissions() {
    local wordpress_owner=$(stat -c '%U:%G' $WORDPRESS_PATH)
    local expected_owner="apache:apache"
    
    if [ "$wordpress_owner" = "$expected_owner" ]; then
        log_message "OK" "WordPress directory has correct ownership: $wordpress_owner"
        return 0
    else
        log_message "WARNING" "WordPress directory ownership: $wordpress_owner (expected: $expected_owner)"
        # Attempt to fix permissions
        log_message "INFO" "Attempting to fix WordPress permissions"
        if chown -R apache:apache $WORDPRESS_PATH; then
            log_message "OK" "WordPress permissions fixed"
            return 0
        else
            log_message "ERROR" "Failed to fix WordPress permissions"
            return 1
        fi
    fi
}

# Function to check database connectivity
check_database_connection() {
    # Extract database configuration from wp-config.php
    if [ -f "$WORDPRESS_PATH/wp-config.php" ]; then
        local db_host=$(grep "DB_HOST" $WORDPRESS_PATH/wp-config.php | cut -d"'" -f4)
        local db_name=$(grep "DB_NAME" $WORDPRESS_PATH/wp-config.php | cut -d"'" -f4)
        local db_user=$(grep "DB_USER" $WORDPRESS_PATH/wp-config.php | cut -d"'" -f4)
        
        if [ -n "$db_host" ] && [ -n "$db_name" ] && [ -n "$db_user" ]; then
            # Test database connectivity (without password for security)
            if command -v mysql >/dev/null 2>&1; then
                # Use wp-config.php to test connection
                local test_result=$(php -r "
                    include '$WORDPRESS_PATH/wp-config.php';
                    \$connection = new mysqli(DB_HOST, DB_USER, DB_PASSWORD, DB_NAME);
                    if (\$connection->connect_error) {
                        echo 'FAILED';
                    } else {
                        echo 'OK';
                        \$connection->close();
                    }
                " 2>/dev/null)
                
                if [ "$test_result" = "OK" ]; then
                    log_message "OK" "Database connection successful"
                    return 0
                else
                    log_message "ERROR" "Database connection failed"
                    return 1
                fi
            else
                log_message "WARNING" "MySQL client not available, skipping database test"
                return 0
            fi
        else
            log_message "WARNING" "Database configuration incomplete in wp-config.php"
            return 1
        fi
    else
        log_message "WARNING" "wp-config.php not found, skipping database test"
        return 1
    fi
}

# Function to check WordPress HTTP response
check_wordpress_response() {
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/ 2>/dev/null)
    
    if [ "$response_code" = "200" ] || [ "$response_code" = "301" ] || [ "$response_code" = "302" ]; then
        log_message "OK" "WordPress responds with HTTP $response_code"
        return 0
    else
        log_message "ERROR" "WordPress responds with HTTP $response_code"
        return 1
    fi
}

# Function to check for WordPress errors
check_wordpress_errors() {
    local error_log="/var/log/httpd/error_log"
    
    if [ -f "$error_log" ]; then
        # Check for recent PHP errors (last 5 minutes)
        local recent_errors=$(find $error_log -mmin -5 -exec grep -i "error\|fatal\|warning" {} \; 2>/dev/null | wc -l)
        
        if [ $recent_errors -eq 0 ]; then
            log_message "OK" "No recent PHP errors found"
            return 0
        else
            log_message "WARNING" "$recent_errors recent PHP errors found in error log"
            return 1
        fi
    else
        log_message "WARNING" "Apache error log not found"
        return 0
    fi
}

# Function to generate health status for ALB
generate_health_status() {
    local health_file="/var/www/html/health.php"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local hostname=$(hostname)
    local instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id 2>/dev/null || echo "unknown")
    
    # Count successful checks
    local total_checks=8
    local passed_checks=$1
    local health_percentage=$((passed_checks * 100 / total_checks))
    
    # Determine overall status
    local status="healthy"
    if [ $health_percentage -lt 100 ]; then
        status="degraded"
    fi
    if [ $health_percentage -lt 50 ]; then
        status="unhealthy"
    fi
    
    # Create or update health check endpoint
    cat > $health_file << EOF
<?php
header('Content-Type: application/json');
header('Cache-Control: no-cache, must-revalidate');

\$health_data = array(
    'status' => '$status',
    'timestamp' => '$timestamp',
    'hostname' => '$hostname',
    'instance_id' => '$instance_id',
    'health_percentage' => $health_percentage,
    'passed_checks' => $passed_checks,
    'total_checks' => $total_checks,
    'uptime' => shell_exec('uptime'),
    'load_average' => sys_getloadavg()[0]
);

echo json_encode(\$health_data, JSON_PRETTY_PRINT);
?>
EOF
    
    chmod 644 $health_file
    chown apache:apache $health_file
}

# Main health check execution
main() {
    log_message "INFO" "Starting health check"
    rotate_log
    
    local passed_checks=0
    local total_checks=0
    
    # Run all health checks
    check_web_server && ((passed_checks++))
    ((total_checks++))
    
    check_disk_space && ((passed_checks++))
    ((total_checks++))
    
    check_memory && ((passed_checks++))
    ((total_checks++))
    
    check_wordpress_files && ((passed_checks++))
    ((total_checks++))
    
    check_wordpress_permissions && ((passed_checks++))
    ((total_checks++))
    
    check_database_connection && ((passed_checks++))
    ((total_checks++))
    
    check_wordpress_response && ((passed_checks++))
    ((total_checks++))
    
    check_wordpress_errors && ((passed_checks++))
    ((total_checks++))
    
    # Generate health status
    generate_health_status $passed_checks
    
    # Final summary
    local health_percentage=$((passed_checks * 100 / total_checks))
    log_message "INFO" "Health check completed: $passed_checks/$total_checks checks passed ($health_percentage%)"
    
    # Exit with appropriate code for external monitoring
    if [ $health_percentage -eq 100 ]; then
        exit 0  # All checks passed
    elif [ $health_percentage -ge 50 ]; then
        exit 1  # Degraded but functional
    else
        exit 2  # Unhealthy
    fi
}

# Execute main function
main "$@"
