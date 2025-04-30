"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const exec_1 = require("@actions/exec");
async function run() {
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
        await (0, exec_1.exec)('bash', [scriptPath], {
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
    }
    catch (error) {
        core.setFailed(`Action failed: ${error instanceof Error ? error.message : String(error)}`);
    }
}
run();
