# Nexus Docker Cleanup Action

A GitHub Action to delete Docker images from a Nexus repository that are older than a specified retention period and do not match protected tags (supports wildcards).

## Inputs

- `nexus-url`: URL of the Nexus server (e.g., `http://nexus.example.com`). Required.
- `nexus-username`: Nexus username with read and delete permissions. Required.
- `nexus-password`: Nexus password. Required.
- `nexus-repository`: Name of the Nexus Docker repository (e.g., `docker-hosted`). Required.
- `protected-tags`: Comma-separated list of tags to protect (supports wildcards, e.g., `latest,prod-*,release-*`). Required.
- `retention-days`: Number of days to retain images (default: `30`).

## Example Usage

```yaml
name: Clean Nexus Docker Images
on:
  schedule:
    - cron: '0 0 \* \* _' # Run daily at midnight UTC
  workflow_dispatch:
jobs:
  cleanup:
  runs-on: ubuntu-latest
  steps:
    - uses: your-org/nexus-docker-cleanup@v1
      with:
        nexus-url: ${{ secrets.NEXUS_URL }}
        nexus-username: ${{ secrets.NEXUS_USERNAME }}
        nexus-password: ${{ secrets.NEXUS_PASSWORD }}
        nexus-repository: ${{ secrets.NEXUS_REPOSITORY }}
        protected-tags: 'latest,prod-_,release-\*'
        retention-days: '30'
```

## Setup

Store sensitive inputs (`nexus-url`, `nexus-username`, `nexus-password`, `nexus-repository`) as GitHub Secrets.
Use the action in your workflow as shown above.
After deletions, request a Nexus admin to run a "Compact Blob Store" task to reclaim disk space.

## Development

Install dependencies: `npm install`
Build: `npm run build`
Package: `npm run package`
