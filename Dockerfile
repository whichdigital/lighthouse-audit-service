# everything below sets up and runs lighthouse
# Using Node.js 22 to meet lighthouse 13.x minimum requirement of >=22.19
FROM node:22-bullseye-slim

# Install Chrome stable and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chromium that Puppeteer
# installs, work.
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
  && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
  && apt-get update \
  && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf dumb-init \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/*

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV CHROME_PATH "google-chrome-stable"

USER node

ENV NPM_CONFIG_PREFIX=/home/node/.npm-global
ENV PATH=$PATH:/home/node/.npm-global/bin

WORKDIR /home/node/app

# install all dev and production dependencies
COPY --chown=node:node package.json .
COPY --chown=node:node package-lock.json .
RUN npm ci

# build and copy the app over
COPY --chown=node:node src ./src
COPY --chown=node:node tsconfig.json .
RUN npm run build

ENV NODE_ENV production

# prune out dev dependencies now that build has completed
RUN npm ci --only=production

CMD ["dumb-init", "node", "cjs/run.js"]
