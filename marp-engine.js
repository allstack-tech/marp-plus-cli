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
  }

  render(markdown, opts = {}) {
    // Preprocess :::mermaid blocks
    const preprocessed = preprocessMermaidBlocks(markdown);
    let { html, ...rest } = super.render(preprocessed, opts);

    // Inline Mermaid.js from node_modules
    let mermaidMin = '';
    try {
      mermaidMin = require('fs').readFileSync(require.resolve('mermaid/dist/mermaid.min.js'), 'utf-8');
    } catch (e) {
      mermaidMin = '';
    }
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

module.exports = MarpMermaidEngine;
