#!/bin/bash

# =============================================================================
# User Data Script for Installing Nginx Web Server
# =============================================================================
# This script is executed when an EC2 instance launches
# It installs and configures Nginx to create a functional web server

# Update system packages to latest versions
echo "Updating system packages..."
yum update -y

# Install Nginx web server
echo "Installing Nginx..."
yum install -y nginx

# Start Nginx service
echo "Starting Nginx service..."
systemctl start nginx

# Enable Nginx to start automatically on boot
echo "Enabling Nginx service for auto-start..."
systemctl enable nginx

# Create a custom index.html page with server information
echo "Creating custom index page..."
cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CloudFormation Web Server</title>
    <style>
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            margin: 0;
            padding: 40px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: #333;
            min-height: 100vh;
        }
        .container {
            max-width: 800px;
            margin: 0 auto;
            background: white;
            padding: 30px;
            border-radius: 15px;
            box-shadow: 0 10px 30px rgba(0,0,0,0.2);
        }
        .header {
            text-align: center;
            margin-bottom: 30px;
            padding-bottom: 20px;
            border-bottom: 3px solid #ff9900;
        }
        .header h1 {
            color: #232f3e;
            margin: 0;
            font-size: 2.5em;
        }
        .success-badge {
            background: #28a745;
            color: white;
            padding: 10px 20px;
            border-radius: 25px;
            display: inline-block;
            margin: 10px 0;
            font-weight: bold;
        }
        .info-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .info-card {
            background: #f8f9fa;
            padding: 20px;
            border-radius: 10px;
            border-left: 4px solid #ff9900;
        }
        .info-card h3 {
            margin-top: 0;
            color: #232f3e;
        }
        .metadata {
            background: #e3f2fd;
            padding: 15px;
            border-radius: 8px;
            margin: 20px 0;
            font-family: monospace;
            font-size: 0.9em;
        }
        .highlight {
            background: #fff3cd;
            padding: 15px;
            border-radius: 8px;
            border-left: 4px solid #ffc107;
            margin: 20px 0;
        }
        .tech-stack {
            display: flex;
            gap: 10px;
            flex-wrap: wrap;
            margin: 15px 0;
        }
        .tech-badge {
            background: #17a2b8;
            color: white;
            padding: 5px 12px;
            border-radius: 15px;
            font-size: 0.85em;
        }
        .footer {
            text-align: center;
            margin-top: 30px;
            padding-top: 20px;
            border-top: 1px solid #dee2e6;
            color: #6c757d;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 CloudFormation Deployment Successful!</h1>
            <div class="success-badge">✅ Infrastructure as Code</div>
        </div>

        <div class="info-grid">
            <div class="info-card">
                <h3>🌐 Web Server Status</h3>
                <p><strong>Status:</strong> Running</p>
                <p><strong>Service:</strong> Nginx</p>
                <p><strong>Port:</strong> 80 (HTTP)</p>
                <p><strong>Auto-configured:</strong> Yes</p>
            </div>

            <div class="info-card">
                <h3>🏗️ Deployment Method</h3>
                <p><strong>Method:</strong> AWS CloudFormation</p>
                <p><strong>Template:</strong> YAML</p>
                <p><strong>Automation:</strong> Complete</p>
                <p><strong>Reproducible:</strong> Yes</p>
            </div>

            <div class="info-card">
                <h3>🔧 Technologies Used</h3>
                <div class="tech-stack">
                    <span class="tech-badge">AWS CloudFormation</span>
                    <span class="tech-badge">Amazon EC2</span>
                    <span class="tech-badge">Amazon VPC</span>
                    <span class="tech-badge">Nginx</span>
                    <span class="tech-badge">Amazon Linux 2</span>
                </div>
            </div>

            <div class="info-card">
                <h3>📊 Architecture</h3>
                <p><strong>Tier:</strong> Web (Public Subnet)</p>
                <p><strong>High Availability:</strong> Multi-AZ</p>
                <p><strong>Security:</strong> Security Groups</p>
                <p><strong>Internet Access:</strong> Internet Gateway</p>
            </div>
        </div>

        <div class="metadata">
            <h3>📋 Instance Metadata</h3>
            <p><strong>Instance ID:</strong> <span id="instance-id">Loading...</span></p>
            <p><strong>Availability Zone:</strong> <span id="az">Loading...</span></p>
            <p><strong>Private IP:</strong> <span id="private-ip">Loading...</span></p>
            <p><strong>Public IP:</strong> <span id="public-ip">Loading...</span></p>
            <p><strong>Region:</strong> <span id="region">Loading...</span></p>
        </div>

        <div class="highlight">
            <h3>🎯 Learning Objectives Achieved</h3>
            <ul>
                <li>✅ <strong>Infrastructure as Code:</strong> Entire architecture defined in a single CloudFormation template</li>
                <li>✅ <strong>Automation:</strong> Zero manual configuration required</li>
                <li>✅ <strong>Repeatability:</strong> Template can be deployed multiple times with consistent results</li>
                <li>✅ <strong>Version Control:</strong> Infrastructure changes can be tracked and reviewed</li>
                <li>✅ <strong>Best Practices:</strong> Parameters, mappings, and outputs used for flexibility</li>
            </ul>
        </div>

        <div class="info-card">
            <h3>🧪 Next Steps</h3>
            <ul>
                <li>Visit the Application Server endpoints (private subnet instances)</li>
                <li>Test the NAT Gateway functionality from private instances</li>
                <li>Explore CloudFormation stack resources in the AWS console</li>
                <li>Try updating the stack with modified parameters</li>
                <li>Practice stack deletion and redeployment</li>
            </ul>
        </div>

        <div class="footer">
            <p>🎓 <strong>AWS Solutions Architect Associate (SAA-C03) Project</strong></p>
            <p>Project 6: Infrastructure as Code with CloudFormation</p>
            <p>Generated automatically via CloudFormation user data script</p>
        </div>
    </div>

    <script>
        // Fetch instance metadata and update the page
        async function fetchMetadata() {
            const metadataBase = 'http://169.254.169.254/latest/meta-data/';
            
            try {
                // Fetch instance metadata
                const instanceId = await fetch(metadataBase + 'instance-id').then(r => r.text());
                const az = await fetch(metadataBase + 'placement/availability-zone').then(r => r.text());
                const privateIp = await fetch(metadataBase + 'local-ipv4').then(r => r.text());
                const publicIp = await fetch(metadataBase + 'public-ipv4').then(r => r.text());
                
                // Update the DOM
                document.getElementById('instance-id').textContent = instanceId;
                document.getElementById('az').textContent = az;
                document.getElementById('private-ip').textContent = privateIp;
                document.getElementById('public-ip').textContent = publicIp;
                document.getElementById('region').textContent = az.slice(0, -1); // Remove last character to get region
            } catch (error) {
                console.log('Could not fetch metadata (normal when testing locally)');
                document.getElementById('instance-id').textContent = 'N/A (local testing)';
                document.getElementById('az').textContent = 'N/A (local testing)';
                document.getElementById('private-ip').textContent = 'N/A (local testing)';
                document.getElementById('public-ip').textContent = 'N/A (local testing)';
                document.getElementById('region').textContent = 'N/A (local testing)';
            }
        }

        // Load metadata when page loads
        window.addEventListener('load', fetchMetadata);
    </script>
</body>
</html>
EOF

# Set proper permissions for the web files
echo "Setting file permissions..."
chmod 644 /var/www/html/index.html
chown nginx:nginx /var/www/html/index.html

# Restart Nginx to ensure all configurations are loaded
echo "Restarting Nginx to apply configurations..."
systemctl restart nginx

# Verify Nginx is running
echo "Verifying Nginx status..."
systemctl status nginx

# Create a simple health check endpoint
echo "Creating health check endpoint..."
cat > /var/www/html/health << 'EOF'
{
  "status": "healthy",
  "service": "nginx",
  "timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "message": "Web server is running successfully"
}
EOF

chmod 644 /var/www/html/health
chown nginx:nginx /var/www/html/health

# Log completion
echo "Web server setup completed successfully!"
echo "Nginx is now running and serving content"
echo "Access the server at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"

# Install CloudWatch agent for monitoring (optional)
echo "Installing CloudWatch agent..."
yum install -y amazon-cloudwatch-agent

# Create a simple log file for debugging
echo "$(date): Web server initialization completed successfully" >> /var/log/web-server-init.log

# Final verification
curl -s http://localhost > /dev/null && echo "Local HTTP test: SUCCESS" || echo "Local HTTP test: FAILED"

echo "=== User Data Script Execution Complete ==="
