// Builds the built-in image library (research R9) from Fluent Emoji SVGs:
// assets/images/bank/<category>/<slug>.webp (768×768, soft circular
// background), manifest.json and LICENSES.md. Development only: the output
// is committed and the app never runs this or touches the network.
//
// Usage (from tool/image_bank): npm ci && npm run build
import { mkdir, readFile, readdir, rm, writeFile } from 'node:fs/promises';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

import { Resvg } from '@resvg/resvg-js';
import sharp from 'sharp';

const toolDir = dirname(fileURLToPath(import.meta.url));
const projectRoot = join(toolDir, '..', '..');
const bankDir = join(projectRoot, 'assets', 'images', 'bank');
const cacheDir = join(toolDir, '.cache');

const imageSize = 768;
// Share of the circle the emoji takes, leaving room for the dial's ring.
const emojiScale = 0.62;
const webpOptions = { quality: 90, effort: 6 };
const manifestSchemaVersion = 1;

const sources = JSON.parse(await readFile(join(toolDir, 'sources.json'), 'utf8'));

await main();

async function main() {
  const { fluentEmoji, categories, images } = sources;
  validateSources(categories, images);

  const entries = [];
  for (const image of images) {
    const svg = await fetchEmojiSvg(fluentEmoji, image.emoji);
    const file = `${image.category}/${image.slug}.webp`;
    await renderImage(svg, categories[image.category], join(bankDir, file));
    entries.push(manifestEntry(fluentEmoji, image, file));
    console.log(`  ${file}`);
  }

  await removeStaleImages(new Set(entries.map((entry) => entry.file)));
  await writeJson(join(bankDir, 'manifest.json'), {
    schemaVersion: manifestSchemaVersion,
    images: entries,
  });
  await writeFile(join(bankDir, 'LICENSES.md'), licensesMarkdown(entries));
  console.log(`Built ${entries.length} images in ${relative(projectRoot, bankDir)}.`);
}

function validateSources(categories, images) {
  const ids = new Set();
  for (const image of images) {
    if (!(image.category in categories)) {
      throw new Error(`${image.slug}: unknown category "${image.category}"`);
    }
    if (!/^[a-z][a-z0-9_]*$/.test(image.slug)) {
      throw new Error(`${image.slug}: slugs must be snake_case`);
    }
    if (!image.names?.pt?.trim() || !image.names?.en?.trim()) {
      throw new Error(`${image.slug}: pt and en names are required`);
    }
    const id = imageId(image);
    if (ids.has(id)) throw new Error(`${id}: duplicated`);
    ids.add(id);
  }
}

/// Downloads the "Color" SVG of [emoji] at the pinned commit, once.
async function fetchEmojiSvg({ repository, commit }, emoji) {
  const cached = join(cacheDir, commit, `${emoji}.svg`);
  try {
    return await readFile(cached, 'utf8');
  } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }

  const url = `https://raw.githubusercontent.com/${repository}/${commit}/${encodeURI(emojiPath(emoji))}`;
  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`${emoji}: GET ${url} failed with ${response.status}`);
  }
  const svg = await response.text();
  await mkdir(dirname(cached), { recursive: true });
  await writeFile(cached, svg);
  return svg;
}

function emojiPath(emoji) {
  const fileStem = emoji.toLowerCase().replaceAll(' ', '_');
  return `assets/${emoji}/Color/${fileStem}_color.svg`;
}

async function renderImage(emojiSvg, background, outputPath) {
  const resvg = new Resvg(composeSvg(emojiSvg, background), {
    fitTo: { mode: 'width', value: imageSize },
    font: { loadSystemFonts: false },
  });
  const png = resvg.render().asPng();
  await mkdir(dirname(outputPath), { recursive: true });
  await sharp(png).webp(webpOptions).toFile(outputPath);
}

/// Nests the emoji, centered, over a radial-gradient circle; outside the
/// circle stays transparent because the dial and thumbnails are round.
function composeSvg(emojiSvg, { center, edge }) {
  const root = emojiSvg.match(/<svg\b[^>]*>/);
  const viewBox = root?.[0].match(/viewBox="([^"]+)"/)?.[1];
  if (!viewBox) throw new Error('Emoji SVG has no root viewBox');
  const content = emojiSvg
    .slice(root.index + root[0].length)
    .replace(/<\/svg>\s*$/, '');

  const radius = imageSize / 2;
  const emojiSize = imageSize * emojiScale;
  const offset = (imageSize - emojiSize) / 2;
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${imageSize}" height="${imageSize}" viewBox="0 0 ${imageSize} ${imageSize}">
<defs><radialGradient id="kid_timer_background" cx="50%" cy="45%" r="60%">
<stop offset="0" stop-color="${center}"/><stop offset="1" stop-color="${edge}"/>
</radialGradient></defs>
<circle cx="${radius}" cy="${radius}" r="${radius}" fill="url(#kid_timer_background)"/>
<svg x="${offset}" y="${offset}" width="${emojiSize}" height="${emojiSize}" viewBox="${viewBox}" fill="none">${content}</svg>
</svg>`;
}

function imageId(image) {
  return `bank:${image.category}/${image.slug}`;
}

function manifestEntry({ repository, commit, author, license }, image, file) {
  return {
    id: imageId(image),
    category: image.category,
    file,
    names: { pt: image.names.pt, en: image.names.en },
    author,
    license,
    source: `https://github.com/${repository}/blob/${commit}/${encodeURI(emojiPath(image.emoji))}`,
  };
}

/// Deletes WebPs left over from images removed from sources.json.
async function removeStaleImages(keptFiles) {
  const files = await readdir(bankDir, { recursive: true });
  for (const file of files) {
    const path = file.replaceAll('\\', '/');
    if (path.endsWith('.webp') && !keptFiles.has(path)) {
      await rm(join(bankDir, file));
      console.log(`  removed ${path}`);
    }
  }
}

async function writeJson(path, value) {
  await writeFile(path, `${JSON.stringify(value, null, 2)}\n`);
}

function licensesMarkdown(entries) {
  const rows = entries.map(
    (entry) => `| \`${entry.file}\` | ${entry.author} | ${entry.license} | <${entry.source}> |`,
  );
  return `# Image licenses

Generated by \`tool/image_bank/build.mjs\` from [Fluent Emoji](https://github.com/${sources.fluentEmoji.repository})
("Color" style, rasterized with a background added). Do not edit by hand.

| File | Author | License | Source |
| ---- | ------ | ------- | ------ |
${rows.join('\n')}

## Fluent Emoji license

MIT License

Copyright (c) Microsoft Corporation.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE
`;
}
