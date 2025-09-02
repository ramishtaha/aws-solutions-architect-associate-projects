# Prerequisites Guide for AWS SAA-C03 Hands-On Projects

## Introduction

Welcome to the prerequisites guide for the "10 Hands-On Projects for AWS Solutions Architect Associate (SAA-C03) Preparation" repository. This document covers all the essential one-time setup steps you need to complete before starting any of the hands-on projects.

**Why complete these prerequisites?**
- Ensures you have the necessary tools and access to work with AWS services
- Establishes security best practices from day one
- Prevents common setup issues that could interrupt your learning flow
- Sets up a professional development environment

**Time required:** Approximately 30-45 minutes for complete setup.

---

## 1. AWS Account Setup

### Creating Your AWS Account

1. **Visit the AWS Sign-Up Page**
   - Go to [aws.amazon.com](https://aws.amazon.com)
   - Click "Create an AWS Account"

2. **Complete the Registration Process**
   - Enter your email address and choose a strong password
   - Provide your contact information
   - Enter payment information (required even for Free Tier)
   - Verify your phone number
   - Choose the "Basic support - Free" plan

3. **Understanding AWS Free Tier**
   - AWS offers a generous Free Tier for new accounts (12 months)
   - Review the [AWS Free Tier](https://aws.amazon.com/free/) page to understand limits
   - Most projects in this repository are designed to stay within Free Tier limits

### Critical Security Setup: Create an IAM User

⚠️ **IMPORTANT SECURITY PRACTICE**: Never use your AWS root account for day-to-day activities.

**Why create an IAM user?**
- **Root account protection**: Your root account has unlimited access to all AWS services and billing
- **Principle of least privilege**: IAM users can have specific permissions
- **Better security**: You can easily disable/rotate IAM user credentials if compromised
- **Audit trail**: IAM user actions are better tracked and logged

**Steps to create an IAM Administrator user:**

1. **Sign in to AWS Console with your root account**
   - Go to [console.aws.amazon.com](https://console.aws.amazon.com)
   - Use your root account credentials (this is the last time!)

2. **Navigate to IAM Service**
   - In the AWS Console search bar, type "IAM"
   - Click on "IAM" from the dropdown

3. **Create a New User**
   - Click "Users" in the left sidebar
   - Click "Create user"
   - Enter username: `admin-user` (or your preferred name)
   - Select "Provide user access to the AWS Management Console"
   - Choose "I want to create an IAM user"
   - Select "Custom password" and enter a strong password
   - Uncheck "Users must create a new password at next sign-in"
   - Click "Next"

4. **Set Permissions**
   - Select "Attach policies directly"
   - Search for and select `AdministratorAccess`
   - Click "Next"

5. **Review and Create**
   - Review the user details
   - Click "Create user"
   - **IMPORTANT**: Save the sign-in URL provided (bookmark it!)

6. **Sign Out and Test**
   - Sign out of the root account
   - Use the IAM user sign-in URL to log in with your new admin user
   - **From now on, always use this IAM user, never the root account**

### Enable MFA (Multi-Factor Authentication) - Recommended

1. **For your IAM admin user:**
   - Go to IAM > Users > your-admin-user
   - Click "Security credentials" tab
   - In the "Multi-factor authentication (MFA)" section, click "Assign MFA device"
   - Follow the setup wizard using a mobile authenticator app (Google Authenticator, Authy, etc.)

---

## 2. AWS CLI Installation and Configuration

### What is the AWS CLI?

The AWS Command Line Interface (CLI) is a unified tool that allows you to manage AWS services from your terminal or command prompt. It's essential for automating tasks and running the commands provided in our project guides.

### Installing AWS CLI

**Choose your operating system:**

#### Windows
1. **Download the AWS CLI MSI installer**
   - Visit: [Installing AWS CLI on Windows](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions)
   - Download the AWS CLI MSI installer for Windows (64-bit)

2. **Run the installer**
   - Double-click the downloaded `.msi` file
   - Follow the installation wizard prompts
   - Accept the default installation location

3. **Verify installation**
   - Open Command Prompt or PowerShell
   - Run: `aws --version`
   - You should see output like: `aws-cli/2.x.x Python/3.x.x Windows/10`

#### macOS
1. **Option 1: Using the GUI installer**
   - Download from: [AWS CLI macOS installer](https://awscli.amazonaws.com/AWSCLIV2.pkg)
   - Double-click the `.pkg` file and follow the installer

2. **Option 2: Using Homebrew (if you have it)**
   ```bash
   brew install awscli
   ```

3. **Verify installation**
   ```bash
   aws --version
   ```

#### Linux
1. **Download and install**
   ```bash
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   ```

2. **Verify installation**
   ```bash
   aws --version
   ```

### Configuring AWS CLI

Before configuring the CLI, you need to generate access keys for your IAM admin user.

#### Step 1: Generate Access Keys

1. **Sign in to AWS Console** with your IAM admin user
2. **Navigate to IAM > Users > your-admin-user**
3. **Click the "Security credentials" tab**
4. **Scroll to "Access keys" section**
5. **Click "Create access key"**
6. **Select "Command Line Interface (CLI)"**
7. **Check the confirmation box and click "Next"**
8. **Add a description tag (optional): "CLI access for SAA-C03 projects"**
9. **Click "Create access key"**

⚠️ **CRITICAL**: The Secret Access Key is shown only once! Copy both keys immediately:
- **Access Key ID**: Starts with `AKIA...`
- **Secret Access Key**: A long random string

**Save these keys securely** - consider using a password manager.

#### Step 2: Configure AWS CLI

Open your terminal/command prompt and run:

```bash
aws configure
```

You'll be prompted for four pieces of information:

1. **AWS Access Key ID**: Paste the Access Key ID you copied above
   ```
   AWS Access Key ID [None]: AKIA...your-access-key...
   ```

2. **AWS Secret Access Key**: Paste the Secret Access Key you copied above
   ```
   AWS Secret Access Key [None]: your-secret-access-key...
   ```

3. **Default region name**: Choose a region close to you for better performance
   ```
   Default region name [None]: us-east-1
   ```
   **Popular regions:**
   - `us-east-1` (N. Virginia) - Often cheapest, required for some services
   - `us-west-2` (Oregon) - Good for US West Coast
   - `eu-west-1` (Ireland) - Good for Europe
   - `ap-southeast-1` (Singapore) - Good for Asia Pacific

4. **Default output format**: Choose how CLI responses are formatted
   ```
   Default output format [None]: json
   ```
   **Options:**
   - `json` (recommended) - Easy to read and parse
   - `table` - Formatted tables (good for viewing)
   - `text` - Plain text output

#### Step 3: Test Your Configuration

```bash
# Test basic connectivity
aws sts get-caller-identity

# Expected output (your values will be different):
{
    "UserId": "AIDACKCEVSQ6C2EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/admin-user"
}
```

If you see an error, double-check your access keys and region configuration.

---

## 3. Recommended Tools

### Code Editor: Visual Studio Code

**Why VS Code?**
- Free and lightweight
- Excellent AWS extensions available
- Built-in terminal integration
- Great for editing JSON, YAML, and configuration files
- Syntax highlighting for various file types

**Installation:**
1. Visit [code.visualstudio.com](https://code.visualstudio.com/)
2. Download for your operating system
3. Run the installer with default settings

**Recommended Extensions:**
After installing VS Code, install these helpful extensions:
- **AWS Toolkit**: Provides AWS service integration
- **JSON**: Better JSON file editing
- **YAML**: For CloudFormation and other YAML files
- **GitLens**: Enhanced Git integration

### Git & GitHub Setup

**Why do you need Git?**
- Clone this repository to your local machine
- Track changes in your project files
- Industry-standard version control
- Required for many development workflows

#### Installing Git

**Windows:**
1. Download from [git-scm.com](https://git-scm.com/download/win)
2. Run the installer with default settings
3. During installation, choose "Use Visual Studio Code as Git's default editor" if you installed VS Code

**macOS:**
```bash
# Using Homebrew (recommended)
brew install git

# Or download from git-scm.com
```

**Linux (Ubuntu/Debian):**
```bash
sudo apt update
sudo apt install git
```

#### Verify Git Installation

```bash
git --version
```

#### GitHub Account (Recommended)

1. **Create a GitHub account** at [github.com](https://github.com) if you don't have one
2. **Why GitHub?**
   - Fork this repository to your own account
   - Save your project modifications
   - Build a portfolio of your AWS learning journey
   - Collaboration and sharing capabilities

#### Clone This Repository

Once you have Git installed:

```bash
# Clone the repository to your local machine
git clone https://github.com/your-username/aws-solutions-architect-associate-projects.git

# Navigate to the project directory
cd aws-solutions-architect-associate-projects

# Open in VS Code (if installed)
code .
```

---

## 4. Additional Recommendations

### Browser Extensions

**JSON Formatter Extensions:**
- **Chrome**: "JSON Formatter" by callumlocke
- **Firefox**: "JSONView" by Ben Hollis
- Makes viewing AWS API responses much easier

### AWS Documentation Bookmarks

Save these essential AWS documentation pages:
- [AWS CLI Command Reference](https://docs.aws.amazon.com/cli/latest/reference/)
- [AWS Service Documentation](https://docs.aws.amazon.com/)
- [AWS Well-Architected Framework](https://docs.aws.amazon.com/wellarchitected/)
- [AWS Free Tier Details](https://aws.amazon.com/free/)

### Cost Management Setup

**Set up billing alerts to avoid surprises:**

1. **Enable Billing Alerts**
   - Go to AWS Console > Billing & Cost Management
   - Click "Billing preferences"
   - Check "Receive Billing Alerts"
   - Save preferences

2. **Create a Budget Alert**
   - Go to AWS Budgets
   - Click "Create budget"
   - Choose "Cost budget"
   - Set amount: $10 (or your comfort level)
   - Set alert threshold: 80% of budgeted amount
   - Add your email for notifications

---

## 5. Troubleshooting Common Issues

### AWS CLI Configuration Issues

**Problem**: `aws sts get-caller-identity` returns "Unable to locate credentials"
**Solution**: 
- Re-run `aws configure`
- Verify your access keys are correct
- Check that your IAM user has the necessary permissions

**Problem**: "Access Denied" errors
**Solution**:
- Verify your IAM user has `AdministratorAccess` policy attached
- Check that you're using the IAM user credentials, not root account

### Region-Related Issues

**Problem**: Some services not available
**Solution**:
- Certain AWS services are only available in specific regions
- For this course, `us-east-1` is recommended as it has the widest service availability

### Cost Concerns

**Problem**: Worried about unexpected charges
**Solution**:
- Always follow the cleanup instructions in each project
- Set up billing alerts as described above
- Review your AWS bill regularly
- Remember: stopping/terminating resources prevents further charges

---

## 6. You're Ready to Start!

✅ **Checklist - Ensure you have completed:**
- [ ] Created AWS account and activated it
- [ ] Created IAM admin user with AdministratorAccess
- [ ] Never use root account for daily activities
- [ ] Installed and configured AWS CLI
- [ ] Successfully tested `aws sts get-caller-identity`
- [ ] Installed VS Code (recommended)
- [ ] Installed Git and cloned the repository
- [ ] Set up billing alerts
- [ ] Bookmarked important AWS documentation

**Next Steps:**
1. Start with [Project 01: Host a Static Website](./01-static-website/README.md)
2. Follow each project in sequence for the best learning experience
3. Always run the cleanup steps after completing each project

---

## Need Help?

- **AWS Documentation**: [docs.aws.amazon.com](https://docs.aws.amazon.com/)
- **AWS CLI Documentation**: [AWS CLI User Guide](https://docs.aws.amazon.com/cli/latest/userguide/)
- **AWS Support**: Use AWS Support Center in your console for account-specific issues
- **Community**: AWS has active communities on Reddit, Stack Overflow, and official forums

**Remember**: Learning AWS is a journey. Don't worry if everything doesn't make perfect sense initially - hands-on practice with these projects will build your understanding over time!

---

*This prerequisites guide is part of the "10 Hands-On Projects for AWS Solutions Architect Associate (SAA-C03) Preparation" repository. Happy learning!*
