# Stage 1: Install dependencies and build the application using Node.js official image
# We switch to the official Node image because it comes with npm pre-installed.
FROM node:20-slim as builder
WORKDIR /usr/src/app

# Copy the ENTIRE source code first
COPY . .

# Use npm to install dependencies. This is more stable for complex monorepos.
# We use 'ci' for reproducible builds in CI environments.
RUN npm ci

# We add NODE_OPTIONS here for the build step inside the container
ENV NODE_OPTIONS=--max-old-space-size=4096
# Build only the 'sim' application
RUN npm run build -- --filter=sim

# Stage 2: Create a slim production image using the Bun runtime
FROM oven/bun:1-slim as runner
WORKDIR /usr/src/app

# Important: Set the working directory to the specific app folder for runtime
WORKDIR /usr/src/app/apps/sim

# Copy only the necessary standalone output from the builder stage
COPY --from=builder /usr/src/app/apps/sim/.next/standalone ./
# Copy public assets
COPY --from=builder /usr/src/app/apps/sim/public ./public
# Copy static assets
COPY --from=builder /usr/src/app/apps/sim/.next/static ./.next/static

ENV NODE_ENV=production
# Expose the port the app runs on
EXPOSE 3000
# The command to start the app (using bun for runtime is fine)
CMD ["bun", "start"]
