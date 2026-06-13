// marp-engine.js
// Minimal Marp engine with tasklist and :::mermaid support

// Marp CLI custom engine module
const { Marp } = require('@marp-team/marp-core');
const markdownItTaskLists = require('markdown-it-task-lists');

// Preprocess :::mermaid blocks to ```mermaid
function preprocessMermaidBlocks(md) {
  return md.replace(/:::mermaid\n([\s\S]*?)\n:::/g, (match, code) => {
    return '```mermaid\n' + code + '\n```';
  });
}
// End of file


const path = require('path');
const fs = require('fs');


class MarpMermaidEngine extends Marp {
  constructor(opts = {}) {
    super({
      ...opts,
      html: true,
      markdown: {
        typographer: true,
        ...(opts.markdown || {}),
      },
    });
    this.markdown.use(markdownItTaskLists, { enabled: true });
    this.resolveRelativeToMd = opts.resolveRelativeToMd || false;
    this.embedImages = process.env.MARP_EMBED_IMAGES ? true : (opts.embedImages !== undefined ? opts.embedImages : false);
  }

  render(markdown, opts = {}) {
    // Try options first
    let mdPath = opts.filePath || opts.mdPath;
    if (!mdPath) {
      // Look for the first .md file in argv
      const argMd = process.argv.find(arg => arg.endsWith(".md"));
      if (argMd) {
        mdPath = path.resolve(argMd);
      }
    }
    const resolveLinks = opts.resolveRelativeToMd !== undefined ? opts.resolveRelativeToMd : this.resolveRelativeToMd;
    const embedImages = opts.embedImages !== undefined ? opts.embedImages : this.embedImages;
    // Preprocess :::mermaid blocks
    const processed = preprocessMermaidBlocks(markdown);
    let { html, ...rest } = super.render(processed, opts);
    // Embed images as base64 if enabled
    if (embedImages && mdPath) {
      const baseDir = path.dirname(mdPath);

      const embedLocalAsset = (src) => {
        if (/^(https?:|data:)/.test(src)) return src;
        const absPath = path.isAbsolute(src) ? src : path.resolve(baseDir, src);
        if (fs.existsSync(absPath)) {
          try {
            const mimeType = getMimeType(absPath);
            const data = fs.readFileSync(absPath);
            const base64 = data.toString('base64');
            return `data:${mimeType};base64,${base64}`;
          } catch (e) {
            console.warn("Could not embed image:", absPath, e.message);
          }
        }
        return src;
      };

      html = html.replace(/<img([^>]*?)src=["']([^"'>]+)["']([^>]*)>/g, (match, pre, src, post) => {
        const embedded = embedLocalAsset(src);
        if (embedded === src) return match;
        return `<img${pre}src="${embedded}"${post}>`;
      });

      html = html.replace(/url\(\s*(?:(&quot;|\"|')(?:\\.|[^\\])*?\1|([^'"\)]+?))\s*\)/g, (match) => {
        const quoteMatch = match.match(/^url\(\s*(&quot;|\"|')/);
        const quote = quoteMatch ? quoteMatch[1] : '';
        const srcMatch = match.match(/url\(\s*(?:&quot;|\"|')?([^'"\)]+?)(?:&quot;|\"|')?\s*\)/);
        if (!srcMatch) return match;
        const src = srcMatch[1];
        const embedded = embedLocalAsset(src);
        if (embedded === src) return match;
        if (quote === '&quot;') {
          return `url(&quot;${embedded}&quot;)`;
        }
        if (quote === '"' || quote === "'") {
          return `url(${quote}${embedded}${quote})`;
        }
        return `url(${embedded})`;
      });
    } else if (resolveLinks) {
      html = MarpMermaidEngine.rewriteRelativeLinks(html, mdPath, true);
    }


    // Mermaid injection unchanged...
    let mermaidMin = '';
    try {
      mermaidMin = fs.readFileSync(require.resolve('mermaid/dist/mermaid.min.js'), 'utf-8');
    } catch (e) {}
    const mermaidScript = `\n<script>${mermaidMin}\n</script>\n<script>\n(function() {\n  mermaid.initialize({ startOnLoad: false });\n  document.querySelectorAll('code.language-mermaid').forEach(function(block, i) {\n    var pre = block.parentElement;\n    var container = document.createElement('div');\n    container.className = 'mermaid';\n    container.innerHTML = block.textContent;\n    pre.parentNode.replaceChild(container, pre);\n  });\n  if (window.mermaid) mermaid.init(undefined, document.querySelectorAll('.mermaid'));
})();\n</script>\n`;
    if (html.includes('</body>')) {
      html = html.replace('</body>', mermaidScript + '</body>');
    } else {
      html += mermaidScript;
    }
    return { html, ...rest };
  }
}

// Helper to guess mime type from file extension
function getMimeType(filePath) {
  const ext = path.extname(filePath).toLowerCase();
  switch (ext) {
    case '.jpg':
    case '.jpeg':
      return 'image/jpeg';
    case '.png':
      return 'image/png';
    case '.gif':
      return 'image/gif';
    case '.svg':
      return 'image/svg+xml';
    case '.webp':
      return 'image/webp';
    default:
      return 'application/octet-stream';
  }
}


module.exports = MarpMermaidEngine;
