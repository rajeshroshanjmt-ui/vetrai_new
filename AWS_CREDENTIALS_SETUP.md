# AWS Credentials Setup Guide for SataGroup (343218220592)

## ⚠️ SECURITY BEST PRACTICES

**IMPORTANT**: AWS credentials are sensitive security tokens. Follow these guidelines:

1. ✅ **DO:**
   - Store credentials securely in `~/.aws/credentials` (local file only)
   - Use IAM Identity Center (recommended option)
   - Rotate credentials regularly
   - Keep session tokens secure and time-limited
   - Use separate credentials per environment (dev/staging/prod)
   - Monitor credential usage in AWS CloudTrail

2. ❌ **DO NOT:**
   - Commit credentials to Git or version control
   - Store credentials in environment variable files (.env) if committed to Git
   - Share credentials via email, Slack, or messaging apps
   - Hardcode credentials in application code
   - Leave credentials in plain text in public locations
   - Store credentials in screenshots or documentation

---

## Option 1: AWS Credentials File (Recommended)

### Step 1: Open PowerShell

```powershell
# Navigate to the credentials file location
$credentialsFile = "$env:USERPROFILE\.aws\credentials"

# Create directory if it doesn't exist
$awsDir = Split-Path $credentialsFile
if (-not (Test-Path $awsDir)) {
    New-Item -ItemType Directory -Path $awsDir -Force | Out-Null
}
```

### Step 2: Add Your Credentials

Edit the credentials file at: `C:\Users\LENOVO\.aws\credentials`

Add the following profile section:

```ini
[343218220592_AdministratorAccess]
aws_access_key_id=YOUR_ACCESS_KEY_HERE
aws_secret_access_key=YOUR_SECRET_KEY_HERE
aws_session_token=YOUR_SESSION_TOKEN_HERE
```

⚠️ **Replace the placeholder values with the credentials provided in your AWS console.**

### Step 3: Set File Permissions (Important for Security)

```powershell
# Make credentials file readable only by owner
icacls "$env:USERPROFILE\.aws\credentials" /inheritance:r /grant:r "%USERNAME%:F"
```

### Step 4: Verify Setup

```powershell
# Test the credentials profile
aws sts get-caller-identity --profile 343218220592_AdministratorAccess

# Expected output:
# {
#     "UserId": "ASIAU72LGNYYL7L3PHFT:...",
#     "Account": "343218220592",
#     "Arn": "arn:aws:iam::343218220592:user/..."
# }
```

---

## Option 2: Environment Variables (Temporary)

### For Current PowerShell Session Only

```powershell
# Set environment variables (values will be cleared when PowerShell closes)
$Env:AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY_HERE"
$Env:AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY_HERE"
$Env:AWS_SESSION_TOKEN="YOUR_SESSION_TOKEN_HERE"
$Env:AWS_PROFILE="343218220592_AdministratorAccess"

# Test connection
aws sts get-caller-identity
```

**Note**: These variables are only valid for the current PowerShell session and will be cleared when you close it.

---

## Option 3: AWS Configuration File

Create/edit `C:\Users\LENOVO\.aws\config` to set default region:

```ini
[profile 343218220592_AdministratorAccess]
region=us-east-1
```

---

## Common AWS CLI Commands to Test

```powershell
# Use specific profile
$Env:AWS_PROFILE = "343218220592_AdministratorAccess"

# Get caller identity (verify credentials work)
aws sts get-caller-identity

# List S3 buckets
aws s3 ls

# List EC2 instances
aws ec2 describe-instances --region us-east-1

# Check IAM user permissions
aws iam list-attached-user-policies --user-name YOUR_USERNAME
```

---

## For Terraform/Infrastructure as Code

### Create `terraform/terraform.tfvars` (DO NOT commit to Git):

```hcl
aws_region              = "us-east-1"
aws_profile             = "343218220592_AdministratorAccess"
```

### Add to `.gitignore`:

```
terraform.tfvars
.env
.env.local
.aws/credentials
.aws/config
```

---

## For Docker/Container Access to AWS

### Option 1: Mount credentials file at runtime

```bash
# Linux/Mac
docker run -v ~/.aws/credentials:/root/.aws/credentials:ro myimage

# Windows PowerShell
docker run -v ($env:USERPROFILE\.aws):/root/.aws:ro myimage
```

### Option 2: Pass environment variables

```bash
docker run `
  -e AWS_ACCESS_KEY_ID=$Env:AWS_ACCESS_KEY_ID `
  -e AWS_SECRET_ACCESS_KEY=$Env:AWS_SECRET_ACCESS_KEY `
  -e AWS_SESSION_TOKEN=$Env:AWS_SESSION_TOKEN `
  myimage
```

---

## Rotating/Refreshing Credentials

Your AWS IAM Identity Center credentials have a limited session duration. To refresh:

### Method 1: AWS IAM Identity Center (Recommended)

```powershell
# Configure AWS CLI to use SSO
aws configure sso

# When prompted:
# SSO start URL: https://d-9067de0711.awsapps.com/start/#
# SSO Region: us-east-1
# CLI default region: us-east-1
# CLI default output: json

# Authenticate
aws sso login --profile 343218220592_AdministratorAccess
```

### Method 2: Manual credential rotation

When your credentials expire, get new ones from the AWS console:
- Visit: https://d-9067de0711.awsapps.com/start/#
- Click on "SataGroup"
- Select "AdministratorAccess"
- Click "Command line or programmatic access"
- Copy new credentials and update `~/.aws/credentials`

---

## Troubleshooting

### Issue: "Unable to locate credentials"

```powershell
# Check if credentials file exists
Test-Path $env:USERPROFILE\.aws\credentials

# Check if environment variables are set
$Env:AWS_ACCESS_KEY_ID
$Env:AWS_SECRET_ACCESS_KEY

# Test with profile explicitly
aws sts get-caller-identity --profile 343218220592_AdministratorAccess
```

### Issue: "UnauthorizedOperation or AccessDenied"

- Verify credentials are correct (no typos)
- Check if credentials have expired (rotate new ones)
- Verify IAM permissions for your user
- Check session token is included

### Issue: "The credential profiles could not be invoked as requested"

```powershell
# Verify profile name
aws configure list --profile 343218220592_AdministratorAccess

# Check file permissions
icacls "$env:USERPROFILE\.aws\credentials"
```

---

## Security Checklist

- [ ] Credentials file is located at: `~/.aws/credentials`
- [ ] File permissions are restricted (owner only)
- [ ] Credentials file is in `.gitignore`
- [ ] Environment variables cleared after use
- [ ] Session tokens rotated regularly
- [ ] CloudTrail logging enabled for account
- [ ] MFA enabled for console access
- [ ] Access keys rotated at least every 90 days
- [ ] Unused access keys deleted

---

## Quick Reference

| Task | Command |
|------|---------|
| Test credentials | `aws sts get-caller-identity --profile 343218220592_AdministratorAccess` |
| List S3 buckets | `aws s3 ls --profile 343218220592_AdministratorAccess` |
| Get current account | `aws sts get-account-summary --profile 343218220592_AdministratorAccess` |
| List IAM users | `aws iam list-users --profile 343218220592_AdministratorAccess` |
| SSO login | `aws sso login --profile 343218220592_AdministratorAccess` |

---

## Resources

- AWS CLI Documentation: https://docs.aws.amazon.com/cli/
- IAM Identity Center: https://docs.aws.amazon.com/singlesignon/
- AWS Credentials: https://docs.aws.amazon.com/general/latest/gr/aws-sec-cred-types.html
- Security Best Practices: https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html

