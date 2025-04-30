#!/bin/bash
set -e

# Validate environment variables
if [ -z "$NEXUS_URL" ] || [ -z "$NEXUS_USERNAME" ] || [ -z "$NEXUS_PASSWORD" ] || [ -z "$NEXUS_REPOSITORY" ] || [ -z "$PROTECTED_TAGS" ] || [ -z "$RETENTION_DAYS" ]; then
  echo "Error: Missing required environment variables (NEXUS_URL, NEXUS_USERNAME, NEXUS_PASSWORD, NEXUS_REPOSITORY, PROTECTED_TAGS, RETENTION_DAYS)"
  exit 1
fi

# Convert protected tags to grep -E pattern (e.g., "latest,prod-*,release-*" -> "latest|prod-.*|release-.*")
PROTECTED_PATTERN=$(echo "$PROTECTED_TAGS" | sed 's/,/|/g' | sed 's/\*/.*/g')
CUTOFF_TIMESTAMP=$(date -d "$RETENTION_DAYS days ago" +%s)

# Get list of repositories
REPOS=$(curl --silent -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
  -H 'Accept: application/json' \
  "$NEXUS_URL/service/rest/v1/components?repository=$NEXUS_REPOSITORY" | \
  jq -r '.items[].name')

if [ -z "$REPOS" ]; then
  echo "No repositories found or error accessing Nexus."
  exit 1
fi

# Iterate over each repository
while IFS= read -r IMAGE_NAME; do
  echo "Processing image: $IMAGE_NAME"

  # Get tags for the image
  TAGS=$(curl --silent -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
    -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
    "$NEXUS_URL/v2/$IMAGE_NAME/tags/list" | jq -r '.tags[]')

  if [ -z "$TAGS" ]; then
    echo "No tags found for $IMAGE_NAME"
    continue
  fi

  # Process each tag
  while IFS= read -r TAG; do
    # Skip protected tags
    if echo "$TAG" | grep -E "$PROTECTED_PATTERN" > /dev/null; then
      echo "Skipping protected tag: $TAG"
      continue
    fi

    # Get manifest to extract last-modified date
    MANIFEST=$(curl --silent -I -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
      -H 'Accept: application/vnd.docker.distribution.manifest.v2+json' \
      "$NEXUS_URL/v2/$IMAGE_NAME/manifests/$TAG")

    LAST_MODIFIED=$(echo "$MANIFEST" | grep -i "Last-Modified" | sed 's/Last-Modified: //I' | tr -d '\r')
    if [ -z "$LAST_MODIFIED" ]; then
      echo "Warning: No Last-Modified date for $IMAGE_NAME:$TAG, skipping"
      continue
    fi

    # Convert last-modified to timestamp
    LAST_MODIFIED_TS=$(date -d "$LAST_MODIFIED" +%s 2>/dev/null || continue)

    # Check if older than retention period
    if [ "$LAST_MODIFIED_TS" -lt "$CUTOFF_TIMESTAMP" ]; then
      # Get manifest digest
      DIGEST=$(echo "$MANIFEST" | grep -i "Docker-Content-Digest" | cut -d ':' -f3 | tr -d '\r')
      if [ -z "$DIGEST" ]; then
        echo "Warning: No digest found for $IMAGE_NAME:$TAG, skipping"
        continue
      fi

      echo "Deleting $IMAGE_NAME:$TAG (Last-Modified: $LAST_MODIFIED)"
      DELETE_URL="$NEXUS_URL/v2/$IMAGE_NAME/manifests/sha256:$DIGEST"
      DELETE_RESPONSE=$(curl --silent -i -u "$NEXUS_USERNAME:$NEXUS_PASSWORD" \
        -X DELETE "$DELETE_URL")

      if echo "$DELETE_RESPONSE" | grep -q "202 Accepted"; then
        echo "Successfully deleted $IMAGE_NAME:$TAG"
      else
        echo "Failed to delete $IMAGE_NAME:$TAG"
        echo "$DELETE_RESPONSE"
      fi
    else
      echo "Tag $IMAGE_NAME:$TAG is newer than $RETENTION_DAYS days, skipping"
    fi
  done <<< "$TAGS"
done <<< "$REPOS"

echo "Cleanup completed."