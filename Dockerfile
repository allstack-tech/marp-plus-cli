# syntax=docker/dockerfile:1


# Build arguments for engine and modules location
ARG ENGINE_DIR=/opt/marp-plus
# Build stage
FROM node:20-alpine AS build
ARG ENGINE_DIR
WORKDIR ${ENGINE_DIR}
COPY package.json ./
RUN npm i --omit=dev --no-optional
COPY . .

# Final minimal image
FROM node:20-alpine AS marp
ARG ENGINE_DIR
WORKDIR /app
# Copy only production node_modules and engine to ENGINE_DIR
COPY --from=build ${ENGINE_DIR}/node_modules ${ENGINE_DIR}/node_modules
COPY --from=build ${ENGINE_DIR}/marp-engine.js ${ENGINE_DIR}/marp-engine.js
# Copy all markdown files to /app
COPY --from=build ${ENGINE_DIR}/*.md ./
# Optionally copy any other needed files
ENV PATH="${ENGINE_DIR}/node_modules/.bin:${PATH}"
ENV ENGINE_FILE="${ENGINE_DIR}/marp-engine.js"

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
CMD ["example.md", "-o", "output.html"]
