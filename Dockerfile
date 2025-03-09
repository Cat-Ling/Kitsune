# Step 1: Use official Node.js 20 Alpine image as base
FROM node:20-alpine AS base

# Step 2: Install libc6-compat for compatibility (sometimes needed for specific dependencies)
FROM base AS deps
RUN apk add --no-cache libc6-compat

# Set working directory
WORKDIR /app

# Step 3: Install dependencies
# Only copy package.json and package-lock.json to install dependencies
COPY package.json package-lock.json ./
RUN npm install

# Step 4: Build the application
FROM base AS builder
WORKDIR /app
# Copy installed node_modules from deps stage
COPY --from=deps /app/node_modules ./node_modules
# Copy the rest of the application code
COPY . .

# Build the app
RUN npm run build

# Step 5: Prepare the production image
FROM base AS runner
WORKDIR /app

# Set environment variable for production
ENV NODE_ENV=production

# Add a non-root user for security reasons
RUN addgroup -g 1001 -S nodejs && adduser -S nextjs -u 1001 -G nodejs

# Copy only the necessary build files from the builder stage
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone/ ./standalone
COPY --from=builder /app/.next/static/ ./static

# Set correct file permissions (so the nextjs user has access to the files)
RUN chown -R nextjs:nodejs /app

# Switch to the non-root user
USER nextjs

# Expose the port that Next.js will run on
EXPOSE 3000

# Set environment variable for the port
ENV PORT=3000

# Define the default command to run the application
CMD ["node", "standalone/server.js"]
