# Stage 1: Install dependencies and build the application using Node.js official image
FROM node:20-slim as builder
WORKDIR /usr/src/app

# Copy the ENTIRE source code first
COPY . .

# Use npm install, ignoring scripts (like husky) which are not needed for the build.
RUN npm install --ignore-scripts

# We add NODE_OPTIONS here for the build step inside the container
ENV NODE_OPTIONS=--max-old-space-size=4096
# Build only the 'sim' application using npm workspaces to bypass turbo's confusion.
RUN npm run build --workspace=sim

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
