/* Wo die Tests hinschauen: die Wurzel dieses Repos. */
import { fileURLToPath } from 'node:url';
import path from 'node:path';

export const ROOT = process.env.APPS_ROOT || path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
