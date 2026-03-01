# API Providers

## Amazon Bedrock

Enable: `CLAUDE_CODE_USE_BEDROCK=1`, `AWS_REGION=us-east-1`

Auth: AWS CLI, env vars, SSO profile, or `AWS_BEARER_TOKEN_BEDROCK`

Model pinning:
```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL='us.anthropic.claude-opus-4-6-v1'
export ANTHROPIC_DEFAULT_SONNET_MODEL='us.anthropic.claude-sonnet-4-6'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='us.anthropic.claude-haiku-4-5-20251001-v1:0'
```

IAM: `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`, `bedrock:ListInferenceProfiles`

## Google Vertex AI

Enable: `CLAUDE_CODE_USE_VERTEX=1`, `CLOUD_ML_REGION=global`, `ANTHROPIC_VERTEX_PROJECT_ID=...`

Model pinning:
```bash
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6'
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-6'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-haiku-4-5@20251001'
```

IAM: `roles/aiplatform.user` with `aiplatform.endpoints.predict`

## Microsoft Foundry

Enable: `CLAUDE_CODE_USE_FOUNDRY=1`, `ANTHROPIC_FOUNDRY_RESOURCE=...`

Auth: `ANTHROPIC_FOUNDRY_API_KEY` or Microsoft Entra ID

RBAC: `Azure AI User` or `Cognitive Services User`

## LLM Gateways

Base URL variables: `ANTHROPIC_BASE_URL`, `ANTHROPIC_BEDROCK_BASE_URL`, `ANTHROPIC_VERTEX_BASE_URL`, `ANTHROPIC_FOUNDRY_BASE_URL`

Gateway must forward `anthropic-beta` and `anthropic-version` headers.

## Model Aliases

| Alias | Description |
|-------|-------------|
| `default` | Max/Premium: Opus; Pro/Standard: Sonnet |
| `sonnet` | Sonnet model |
| `opus` | Opus model |
| `haiku` | Haiku model |
| `sonnet[1m]` | Sonnet with 1M context |
| `opusplan` | Opus in plan mode, Sonnet for execution |
