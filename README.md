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

## Features
- **Task Lists:** Rendered via `markdown-it-task-lists` plugin
- **Mermaid Diagrams:** Supports regular fenced mermaid `'''mermaid` and Azure DevOps wiki fenced  `:::mermaid` blocks in markdown; diagrams are rendered in the browser with inlined Mermaid.js
- **Presentation UI:** Uses Marp CLI for full-featured HTML output
- **Offline Support:** Mermaid.js is inlined, so no internet access is required to view diagrams
- **Multi-stage Docker Build:** Keeps image size minimal and dependencies isolated
- **CI/CD:** Automated build, release (with Docker Hub push), and monthly dependency update workflows

## Usage

### Build the Docker Image
```sh
docker build -t marp-plus-cli .
```

### Render a Markdown File
```sh
docker run --rm -v "$PWD:/app" marp-plus-cli example.md -o output.html
```
**Note:** You do not need to mount your entire project directory to `/app` , instead, mount only the markdown/output/css file as needed:
```sh
docker run --rm -v "$PWD/example.md:/app/example.md" -v "$PWD/output.html:/app/output.html" marp-plus-cli example.md -o output.html
```

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
