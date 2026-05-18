# Cloud Formation — Deploy Guide

Region: **us-west-2**

**Needs:** [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html), [Node.js](https://nodejs.org/)

## 1. Setup AWS CLI (one time)

```bash
aws configure
# region: us-west-2
# output: json

aws sts get-caller-identity
```

```cmd
aws configure
aws sts get-caller-identity
```

---

## 2. Backend (Lambda + API)

**Mac / Linux**

```bash
cd backend
npm install

./infra/script/deploy.sh dev
./infra/script/test.sh dev
./infra/script/destroy.sh dev
```

**Windows** (Command Prompt)

```cmd
cd backend
npm install

infra\script\deploy.cmd dev
infra\script\test.cmd dev
infra\script\destroy.cmd dev
```

Stages: `dev` | `staging` | `prod`

---

## 3. Frontend (S3 + CloudFront)

**Mac / Linux**

```bash
./frontend/infra/script/deploy.sh dev
./frontend/infra/script/build.sh dev
./frontend/infra/script/destroy.sh dev
```

**Windows**

```cmd
frontend\infra\script\deploy.cmd dev
frontend\infra\script\build.cmd dev
frontend\infra\script\destroy.cmd dev
```

Deploy prints **WebsiteUrl** (HTTPS link).

---

## Order

1. **Backend** first  
2. **Frontend** second
