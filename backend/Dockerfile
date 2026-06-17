FROM node:18-alpine

WORKDIR /usr/src/app

# Copy package info and install dependencies at the root directory so database models can resolve them
COPY backend/package*.json ./
RUN npm install --production

# Copy backend and database folders relative to project root
COPY backend/ ./backend/
COPY database/ ./database/

# Ensure no duplicate node_modules are copied from the host (which causes double-instantiated mongoose conflicts)
RUN rm -rf backend/node_modules

EXPOSE 5000

CMD ["node", "backend/server.js"]

