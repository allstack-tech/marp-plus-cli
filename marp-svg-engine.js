// marp-engine.js
// Minimal Marp engine with tasklist and :::mermaid support

const fs = require('fs');
const { Marp } = require('@marp-team/marp-core');
const markdownItTaskLists = require('markdown-it-task-lists');
const puppeteer = require('puppeteer');
const mermaid = require('mermaid');



// Render Mermaid code to SVG using Puppeteer and the mermaid API
async function renderMermaidToSVG(code) {
  const browser = await puppeteer.launch({
    args: ['--no-sandbox', '--disable-setuid-sandbox'],
    executablePath: process.env.PUPPETEER_EXECUTABLE_PATH || undefined,
    });
  const page = await browser.newPage();
  await page.setContent(`
    <body>
      <div id="container"></div>
      <script type="module">
        import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
        window.mermaid = mermaid;
      <\/script>
    </body>
  `, { waitUntil: 'domcontentloaded' });
  // Wait for mermaid to be available
  await page.waitForFunction('window.mermaid');
  // Render SVG
  const svg = await page.evaluate(async (code) => {
    await window.mermaid.initialize({ startOnLoad: false });
    const { svg } = await window.mermaid.render('theGraph', code);
    return svg;
  }, code);
  await browser.close();
  return svg;
}

// Replace :::mermaid blocks with rendered SVGs
async function preprocessMermaidBlocksToSVG(md) {
  const mermaidBlockRegex = /:::mermaid\n([\s\S]*?)\n:::/g;
  let match;
  let out = '';
  let lastIndex = 0;
  while ((match = mermaidBlockRegex.exec(md)) !== null) {
    out += md.slice(lastIndex, match.index);
    const code = match[1];
    let svg = '';
    try {
      svg = await renderMermaidToSVG(code);
    } catch (e) {
      svg = `<pre>Mermaid render error: ${e.message}</pre>`;
    }
    out += svg;
    lastIndex = mermaidBlockRegex.lastIndex;
  }
  out += md.slice(lastIndex);
  return out;
}

async function main() {
  const inputFile = process.argv[2] || 'example.md';
  const outputFile = process.argv[3] || 'output.html';

  const md = fs.readFileSync(inputFile, 'utf-8');
  const preprocessed = await preprocessMermaidBlocksToSVG(md);

  const marp = new Marp({
    html: true,
    markdown: {
      typographer: true,
    },
  });
  marp.markdown.use(markdownItTaskLists, { enabled: true });

  let { html } = marp.render(preprocessed);
  fs.writeFileSync(outputFile, html);
  console.log(`Rendered ${inputFile} to ${outputFile}`);
}

main();
