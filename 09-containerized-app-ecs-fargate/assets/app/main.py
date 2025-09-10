from flask import Flask
import os

app = Flask(__name__)

@app.route('/')
def hello():
    """
    Main route that returns a greeting message from the Fargate container.
    This demonstrates that the containerized application is running successfully.
    """
    return '''
    <html>
        <head>
            <title>Hello from Fargate!</title>
            <style>
                body { font-family: Arial, sans-serif; margin: 50px; background-color: #f0f0f0; }
                .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
                h1 { color: #232F3E; }
                .info { background-color: #e8f4fd; padding: 15px; border-radius: 5px; margin-top: 20px; }
            </style>
        </head>
        <body>
            <div class="container">
                <h1>🎉 Hello from AWS Fargate!</h1>
                <p>Congratulations! Your containerized web application is running successfully on Amazon ECS with AWS Fargate.</p>
                <div class="info">
                    <strong>Container Info:</strong><br>
                    • Application: Python Flask Web Server<br>
                    • Platform: AWS Fargate (Serverless Containers)<br>
                    • Port: 8080<br>
                    • Status: ✅ Running
                </div>
            </div>
        </body>
    </html>
    '''

@app.route('/health')
def health_check():
    """
    Health check endpoint for the Application Load Balancer.
    This endpoint is used by the ALB to determine if the container is healthy.
    """
    return {
        "status": "healthy",
        "service": "flask-fargate-app",
        "port": 8080
    }

if __name__ == '__main__':
    # Run the Flask application on port 8080
    # In production, Fargate will expose this port through the ALB
    port = int(os.environ.get('PORT', 8080))
    app.run(host='0.0.0.0', port=port, debug=False)
