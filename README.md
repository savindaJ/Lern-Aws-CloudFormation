# Cloud Formation — Deploy Guide

Region: **us-west-2**

## 1. Setup AWS CLI (one time)

```bash
# Install: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

aws configure
# AWS Access Key ID:     <your key>
# AWS Secret Access Key: <your secret>
# Default region:        us-west-2
# Default output:        json

aws sts get-caller-identity   # verify login
```

---

## 2. Backend (Serverless — Lambda + API)

```bash
cd backend
npm install

./infra/script/deploy.sh dev
./infra/script/deploy.sh staging
./infra/script/deploy.sh prod

./infra/script/test.sh dev
./infra/script/destroy.sh dev
```

---

## 3. Frontend (CloudFormation — S3 + CloudFront)

```bash
./frontend/infra/script/deploy.sh dev
./frontend/infra/script/deploy.sh staging
./frontend/infra/script/deploy.sh prod

./frontend/infra/script/build.sh dev      # build only
./frontend/infra/script/destroy.sh dev
```

Deploy prints **WebsiteUrl** (your live HTTPS link).

---

## Order

1. Deploy **backend** first  
2. Deploy **frontend** (picks up API URL automatically)
