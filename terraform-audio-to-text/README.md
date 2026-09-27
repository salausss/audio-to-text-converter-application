# audio-to-text — Terraform

Same stack as the SAM version, rebuilt as modular Terraform:

- `modules/s3-storage` — temp audio bucket (1-day expiry, blocked public access)
- `modules/lambda-function` — reusable module, instantiated twice (get-upload-url, transcribe); handles `npm install`, zipping, IAM role/policy, log group, and the public Function URL
- `modules/static-frontend` — public S3 static website bucket; renders `frontend/index.html.tftpl`, injecting both Lambda Function URLs at apply time so nothing is hardcoded

Root `main.tf` wires them together. `terraform apply` alone builds everything: installs each Lambda's dependencies, zips them, deploys both functions, creates the frontend bucket, and uploads the templated `index.html` with the live endpoint URLs baked in.

## Usage

```bash
cp terraform.tfvars.example terraform.tfvars
# edit terraform.tfvars: set assemblyai_api_key (from console.assemblyai.com)

terraform init
terraform apply
```

On success, check the `website_url` output — that's the page to open.

## Notes

- Requires Node.js + npm on the machine running `terraform apply` (the Lambda module shells out to `npm install` as part of the build).
- `terraform destroy` cleans up everything, including the two S3 buckets (`force_destroy = true` on both, so leftover objects won't block deletion).
- Re-running `apply` after editing a Lambda's `index.mjs` picks up the change automatically (`source_code_hash` is derived from the zip). Editing only `package.json` also triggers `npm install` again via the `null_resource` trigger.
