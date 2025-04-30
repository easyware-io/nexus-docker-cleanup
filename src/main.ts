import * as core from '@actions/core';
import { exec } from '@actions/exec';

async function run(): Promise<void> {
  try {
    // Get inputs
    const nexusUrl = core.getInput('nexus-url', { required: true });
    const nexusUsername = core.getInput('nexus-username', { required: true });
    const nexusPassword = core.getInput('nexus-password', { required: true });
    const nexusRepository = core.getInput('nexus-repository', { required: true });
    const protectedTags = core.getInput('protected-tags', { required: true });
    const retentionDays = parseInt(core.getInput('retention-days') || '30', 10);

    if (isNaN(retentionDays) || retentionDays < 0) {
      core.setFailed('Invalid retention-days: must be a non-negative number');
      return;
    }

    // Path to the bash script
    const scriptPath = './cleanup.sh';

    // Execute the bash script with environment variables
    await exec('bash', [scriptPath], {
      env: {
        ...process.env,
        NEXUS_URL: nexusUrl,
        NEXUS_USERNAME: nexusUsername,
        NEXUS_PASSWORD: nexusPassword,
        NEXUS_REPOSITORY: nexusRepository,
        PROTECTED_TAGS: protectedTags,
        RETENTION_DAYS: retentionDays.toString(),
      },
    });

    core.info('Nexus Docker cleanup completed successfully.');
  } catch (error) {
    core.setFailed(`Action failed: ${error instanceof Error ? error.message : String(error)}`);
  }
}

run();
