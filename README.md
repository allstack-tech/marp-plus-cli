# marp-plus-cli

Minimal Marp + Mermaid + Tasklist Dockerized Presentation Engine

## Overview

This project provides a minimal, Dockerized Marp engine capable of rendering Marp markdown documents with:
- GitHub-style task lists
- Mermaid diagrams (using custom `:::mermaid` fenced blocks)
- Fully inlined Mermaid.js for offline rendering
- Custom engine for Marp CLI, supporting presentation and slide views

It includes:
- Custom Marp engine (`marp-engine.js`) for preprocessing and rendering
- Dockerfile for reproducible, minimal images
- GitHub Actions pipelines for build, release, and monthly dependency updates

## Version 1.3.0 Updates
- Added `--keep-dirs` to preserve source markdown directory structure inside the output directory.
- Added `--embed-images` to optionally inline local images into generated HTML.
- Embedding is now opt-in to avoid unexpectedly larger output bundles.
- Continued support for remote theme CSS URLs passed to `--theme` and `--theme-set`.
- Added better directory-aware output handling for theme-filtered multi-file rendering.

## Version 1.2.0 Updates
- Added support for remote theme CSS URLs passed to `--theme` and `--theme-set` by downloading the files locally before Marp runs.
- Added `test.sh` as a repository helper script to build the Docker image, render the `sub/` directory with theme filtering, and verify generated output.
- Fixed theme-filtered directory rendering so `output/` is written correctly when processing matching files.
- Added alias-style theme matching for names like `tech-marp` to match `atech-marp` in markdown front matter.

## Features
- **Task Lists:** Rendered via `markdown-it-task-lists` plugin
- **Mermaid Diagrams:** Supports regular fenced mermaid `'''mermaid` and Azure DevOps wiki fenced  `:::mermaid` blocks in markdown; diagrams are rendered in the browser with inlined Mermaid.js
- **Presentation UI:** Uses Marp CLI for full-featured HTML output
- **Offline Support:** Mermaid.js is inlined, so no internet access is required to view diagrams
- **Recursive Directory Processing:** Process entire directories of markdown files in a single command
- **Theme Filtering:** Filter which markdown files are processed based on their theme directive
- **Multi-stage Docker Build:** Keeps image size minimal and dependencies isolated
- **CI/CD:** Automated build, release (with Docker Hub push), and monthly dependency update workflows

## Usage

### Build the Docker Image
```sh
docker build -t marp-plus-cli .
```

### Render a Single Markdown File
```sh
docker run --rm -v "$PWD:/app" marp-plus-cli example.md -o output.html
```
**Note:** You do not need to mount your entire project directory to `/app` , instead, mount only the markdown/output/css file as needed:
```sh
docker run --rm -v "$PWD/example.md:/app/example.md" -v "$PWD/output.html:/app/output.html" marp-plus-cli example.md -o output.html
```

### Render a Directory Recursively
Process all markdown files in a directory:
```sh
docker run --rm -v "$PWD/input:/input" -v "$PWD/output:/output" marp-plus-cli /input -o /output/
```

### Render with Theme Filter
Process only markdown files with a specific theme:
```sh
# Filter by built-in theme (e.g., gaia)
docker run --rm -v "$PWD/input:/input" -v "$PWD/output:/output" marp-plus-cli /input --theme-filter "gaia" -o /output/

# Filter by custom theme path (normalizes ./themes/custom.css and themes/custom.css as equivalent)
docker run --rm -v "$PWD/input:/input" -v "$PWD/output:/output" marp-plus-cli /input --theme-filter "themes/custom.css" -o /output/
```

**Note:** Theme filtering only applies to directories. Files without a theme directive in their YAML front matter will be skipped when using `--theme-filter`.

### Image and Directory Options
Use `--keep-dirs` to preserve source folder structure in the output directory.
Use `--embed-images` to inline local image assets into generated HTML.
```sh
# Preserve relative directories and embed images into output HTML
docker run --rm -v "$PWD/input:/input" -v "$PWD/output:/output" marp-plus-cli /input --theme-filter "gaia" --keep-dirs --embed-images -o /output/
```

The `--embed-images` flag is opt-in so HTML output size stays under control unless the user explicitly requests embedding.

### Custom Engine
The Marp CLI uses `marp-engine.js` as a custom engine to preprocess Mermaid blocks and inject Mermaid.js. This enables both presentation UI and browser-based diagram rendering.

## Mermaid Diagrams
You can use the following syntax in your markdown:
```
:::mermaid
graph TD;
  A-->B;
  A-->C;
  B-->D;
  C-->D;
:::
```

## GitHub Actions Workflows
- **Build:** Builds the Docker image on changes to core files
- **Release:** On main branch, tags and pushes the Docker image to Docker Hub
- **Monthly Update:** Updates dependencies and creates a PR if changes are found
- **Version Check:** Ensures non-main builds have a version greater than main

## Development
- All dependencies are installed inside the Docker image; no need to run `npm install` locally
- To update dependencies, edit `package.json` and rebuild the image
- For SSH key management, use an SSH config file to specify keys for different GitHub orgs

## License
MIT

## Maintainers
- allstack-tech

## Contributing
Pull requests and issues are welcome. Please ensure your branch version is greater than main before merging.
