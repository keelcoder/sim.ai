# Stage 1: Install dependencies and build the application
FROM oven/bun:1 as builder
WORKDIR /usr/src/app

# Copy the ENTIRE source code first, so bun can see the whole monorepo
COPY . .

# Now, run install. It will install dependencies for all workspaces.
RUN bun install

# We add NODE_OPTIONS here for the build step inside the container
ENV NODE_OPTIONS=--max-old-space-size=4096
# Build only the 'sim' application
RUN bun run build --filter=sim

# Stage 2: Create a slim production image
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
# The command to start the app
CMD ["bun", "start"]
