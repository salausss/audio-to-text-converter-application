# Free Audio-to-Text — AWS pay-per-use deployment

Architecture: browser → Lambda (presigned URL) → browser uploads straight to S3
→ Lambda downloads from S3 → calls Groq's Whisper API → returns transcript →
temp file deleted. No servers, no API Gateway, no idle cost.

---

## 0. Prerequisites

- An AWS account (not your personal/root login for daily use — see step 2)
- Node.js 20+ installed locally (only needed for local testing, not required to deploy)
- A Groq API key: sign up free at https://console.groq.com → API Keys
- A domain name (optional, can add later)

---

## 1. Install the tools

```bash
# AWS CLI
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"   # macOS
# or see https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# AWS SAM CLI (packages/deploys the template.yaml in this project)
# macOS:
brew tap aws/tap && brew install aws-sam-cli
# Windows/Linux: see https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html
```

Verify:
```bash
aws --version
sam --version
```

---

## 2. Create a limited IAM user (don't deploy with your root account)

1. AWS Console → IAM → Users → Create user
2. Attach policy `AdministratorAccess` for now (fine for a solo project; tighten later)
3. Create an access key (IAM → your user → Security credentials → Create access key → "Command Line Interface")
4. On your machine:
   ```bash
   aws configure
   # paste Access Key ID, Secret Access Key, pick a region e.g. us-east-1
   ```

---

## 3. Set a cost safety net (do this before deploying anything)

AWS Console → Billing → Budgets → Create budget → "Zero spend budget" or a
custom $5/month budget with an email alert. This guarantees you find out
immediately if something runs away, rather than at the end of the month.

---

## 4. Deploy the backend

From this project's root folder:

```bash
sam build
sam deploy --guided
```

During the guided deploy it will ask you:
- Stack Name: e.g. `audio-to-text`
- AWS Region: pick one close to your users, e.g. `us-east-1`
- Parameter `GroqApiKey`: paste your Groq API key
- Confirm changes before deploy: Y
- Allow SAM CLI IAM role creation: Y
- Save arguments to samconfig.toml: Y (so future deploys are just `sam deploy`)

When it finishes, it prints an **Outputs** section — copy the two values:

```
GetUploadUrlEndpoint: https://xxxxxxxxxxxx.lambda-url.us-east-1.on.aws/
TranscribeEndpoint:   https://yyyyyyyyyyyy.lambda-url.us-east-1.on.aws/
```

---

## 5. Wire up the frontend

Open `frontend/index.html` and replace:

```js
const GET_UPLOAD_URL_ENDPOINT = "https://REPLACE-ME.lambda-url.us-east-1.on.aws/";
const TRANSCRIBE_ENDPOINT = "https://REPLACE-ME.lambda-url.us-east-1.on.aws/";
```

with the two URLs from the deploy output.

---

## 6. Host the frontend

**Simplest option (recommended to start):** upload `frontend/index.html` to
Cloudflare Pages, Vercel, or Netlify's free tier — drag-and-drop deploy,
zero config, and you keep AWS purely as your pay-per-use backend.

**All-AWS option:**
```bash
aws s3 mb s3://your-frontend-bucket-name
aws s3 website s3://your-frontend-bucket-name --index-document index.html
aws s3 cp frontend/index.html s3://your-frontend-bucket-name/ --acl public-read
```
Then optionally put CloudFront in front of it for HTTPS + a custom domain
(Console → CloudFront → Create distribution → origin = your S3 website
endpoint).

---

## 7. Test it

Open the hosted `index.html` in a browser, drop in a short audio clip, and
confirm you get a transcript back. Check AWS Console → Lambda → your two
functions → Monitor → Logs if something fails.

---

## 8. Add a custom domain (optional, later)

1. Route 53 → Register domain, or use an existing domain and just add its
   nameservers to a Route 53 hosted zone (~$0.50/month for the hosted zone).
2. ACM (in us-east-1 if using CloudFront) → request a free SSL certificate
   for your domain.
3. CloudFront distribution → attach the certificate + your domain as an
   alternate domain name.
4. Route 53 → create an A record (alias) pointing at the CloudFront
   distribution.

---

## Cost recap

| Component | Idle cost | Cost per use |
|---|---|---|
| S3 (temp audio) | ~$0 (auto-deleted within 1 day, usually seconds) | fractions of a cent |
| Lambda x2 | $0 (1M free requests/month, always-free tier) | ~$0.0000002 per request after that |
| Groq Whisper API | $0 | ~$0.0006/minute of audio |
| CloudWatch Logs | $0 (7-day retention keeps it capped) | negligible |
| Domain (optional) | ~$1/month equivalent | — |

Nothing in this stack bills you for sitting idle. The only recurring cost is
the domain, if you choose to add one.
