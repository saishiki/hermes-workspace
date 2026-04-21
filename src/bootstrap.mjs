process.on('uncaughtException', (err) => {
  console.error('[bootstrap] uncaughtException');
  console.error(err?.stack || err);
  process.exit(1);
});

process.on('unhandledRejection', (reason) => {
  console.error('[bootstrap] unhandledRejection');
  console.error(reason);
  process.exit(1);
});

console.log('[bootstrap] starting workspace');
console.log('[bootstrap] cwd:', process.cwd());
console.log('[bootstrap] PORT:', process.env.PORT);
console.log('[bootstrap] HOST:', process.env.HOST);
console.log('[bootstrap] HERMES_API_URL:', process.env.HERMES_API_URL);
console.log('[bootstrap] HERMES_API_TOKEN set:', Boolean(process.env.HERMES_API_TOKEN));

try {
  const fs = await import('node:fs');
  const path = await import('node:path');

  const filesToCheck = [
    'server-entry.js',
    'dist/server/server.js',
    'dist/client',
  ];

  for (const file of filesToCheck) {
    const full = path.resolve(file);
    console.log(`[bootstrap] exists ${full}:`, fs.existsSync(full));
  }
} catch (err) {
  console.error('[bootstrap] file check failed');
  console.error(err?.stack || err);
}

await import('./server-entry.js');
