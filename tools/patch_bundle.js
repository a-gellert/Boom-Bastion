#!/usr/bin/env node
// tools/patch_bundle.js — post-build web polish.
// Copies the app icon and the Poki SDK bridge into the bundle and injects favicon,
// theme and social meta into Defold's index.html.
//
//   node tools/patch_bundle.js "bundle/web/Bastion Blast"

'use strict';

const fs = require('fs');
const path = require('path');

const ROOT = path.resolve(__dirname, '..');
const APP = process.argv[2];
if (!APP) {
  console.error('usage: node tools/patch_bundle.js <app_dir>');
  process.exit(2);
}

const app = path.resolve(APP);
const index = path.join(app, 'index.html');
if (!fs.existsSync(index)) {
  console.error('index.html not found in', app);
  process.exit(1);
}

const ICON = path.join(ROOT, 'main', 'assets', 'icon.png');
const POKI = path.join(ROOT, 'tools', 'web', 'poki.js');
for (const [src, name] of [[ICON, 'icon.png'], [POKI, 'poki.js']]) {
  if (!fs.existsSync(src)) {
    console.error('missing', src);
    process.exit(1);
  }
  fs.copyFileSync(src, path.join(app, name));
}

const MARK = '<!-- bastion-web-meta -->';
const META = `${MARK}
<meta name="theme-color" content="#0b1222">
<meta name="description" content="Bastion Blast - turn-based castle demolition. Pull, release, collapse the enemy keep.">
<meta property="og:title" content="Bastion Blast">
<meta property="og:description" content="Turn-based castle demolition: pull, release, collapse the enemy keep.">
<meta property="og:type" content="website">
<meta property="og:image" content="icon.png">
<link rel="icon" type="image/png" sizes="512x512" href="icon.png">
<link rel="apple-touch-icon" href="icon.png">
<style>html,body{background:#0b1222}</style>
<script src="poki.js"></script>`;

let html = fs.readFileSync(index, 'utf8');
if (!html.includes(MARK)) {
  if (!html.includes('</head>')) {
    console.error('no </head> in index.html');
    process.exit(1);
  }
  html = html.replace('</head>', `${META}\n</head>`);
}
if (/<title>[^<]*<\/title>/i.test(html)) {
  html = html.replace(/<title>[^<]*<\/title>/i, '<title>Bastion Blast</title>');
} else {
  html = html.replace('</head>', '<title>Bastion Blast</title>\n</head>');
}
fs.writeFileSync(index, html);

console.log('WEB PATCH OK (icon, favicon, meta, poki bridge)');
