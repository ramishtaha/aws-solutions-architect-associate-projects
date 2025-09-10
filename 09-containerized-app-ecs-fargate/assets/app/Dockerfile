# Multi-stage Dockerfile for Python Flask Application
# This Dockerfile creates a lightweight, production-ready container image

# Stage 1: Build stage
# Use the official Python runtime as the base image
FROM python:3.11-slim as builder

# Set the working directory in the container
WORKDIR /app

# Copy the requirements file to leverage Docker cache layers
# This allows Docker to cache the pip install step if requirements don't change
COPY requirements.txt .

# Install Python dependencies
# --no-cache-dir: Don't cache downloaded packages to reduce image size
# --user: Install packages to user directory to avoid permission issues
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Production stage
# Start with a fresh, minimal Python image
FROM python:3.11-slim

# Create a non-root user for security best practices
# Running containers as root is a security risk
RUN useradd --create-home --shell /bin/bash app

# Set the working directory
WORKDIR /app

# Copy the installed Python packages from the builder stage
COPY --from=builder /root/.local /home/app/.local

# Copy the application code
COPY main.py .

# Change ownership of the app directory to the app user
RUN chown -R app:app /app

# Switch to the non-root user
USER app

# Make sure the user's local bin directory is in PATH
ENV PATH=/home/app/.local/bin:$PATH

# Expose port 8080 for the Flask application
# This is the port that the container will listen on
EXPOSE 8080

# Add a health check to monitor container health
# This helps ECS determine if the container is running properly
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Use gunicorn as the WSGI server for production deployment
# gunicorn provides better performance and stability than Flask's built-in server
CMD ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--timeout", "30", "main:app"]
