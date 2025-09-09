#!/bin/bash

# Update the system packages
yum update -y

# Install Nginx web server
yum install -y nginx

# Start Nginx service
systemctl start nginx

# Enable Nginx to start automatically on boot
systemctl enable nginx

# Create a custom index.html file to verify the setup
cat > /var/share/nginx/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Three-Tier Architecture - Web Server</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            margin: 40px;
            background-color: #f0f8ff;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background-color: white;
            padding: 30px;
            border-radius: 10px;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
        }
        h1 {
            color: #2c3e50;
            text-align: center;
        }
        .success {
            background-color: #d4edda;
            color: #155724;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
        .info {
            background-color: #d1ecf1;
            color: #0c5460;
            padding: 15px;
            border-radius: 5px;
            margin: 20px 0;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎉 Web Tier Successfully Deployed!</h1>
        
        <div class="success">
            <strong>Success!</strong> Your Nginx web server is running in the Public Subnet of your Three-Tier VPC Architecture.
        </div>
        
        <div class="info">
            <h3>Architecture Overview:</h3>
            <ul>
                <li><strong>Web Tier (Current):</strong> Public subnet with internet access</li>
                <li><strong>Application Tier:</strong> Private subnet (no direct internet access)</li>
                <li><strong>Database Tier:</strong> Private subnet (most secure)</li>
            </ul>
        </div>
        
        <p><strong>Instance Details:</strong></p>
        <ul>
            <li>Server: Nginx Web Server</li>
            <li>Location: Public Subnet</li>
            <li>Access: Internet Gateway</li>
            <li>Security: Configured Security Groups</li>
        </ul>
        
        <p><em>This page confirms that your web server has proper internet connectivity and is serving content successfully.</em></p>
    </div>
</body>
</html>
EOF

# Set proper permissions
chmod 644 /var/share/nginx/html/index.html

# Restart Nginx to ensure all changes take effect
systemctl restart nginx

# Display status for verification
echo "Nginx installation completed!"
echo "Status: $(systemctl is-active nginx)"
echo "Enabled: $(systemctl is-enabled nginx)"
