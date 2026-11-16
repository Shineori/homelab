# Shineori build of kitsteam/excalidraw (Firebase-free fork) with self-hosted collab URLs
FROM node:22 AS build
WORKDIR /opt/node_app
COPY package.json yarn.lock ./
COPY excalidraw-app/package.json ./excalidraw-app/
COPY packages/excalidraw/package.json ./packages/excalidraw/
COPY packages/common/package.json ./packages/common/
COPY packages/element/package.json ./packages/element/
COPY packages/math/package.json ./packages/math/
RUN --mount=type=cache,target=/usr/local/share/.cache/yarn yarn --network-timeout 600000
COPY . .
COPY shineori/env.production .env.production
# Shineori: skip kitsteam's German school landing page, open the app at / (old /app links still work)
RUN sed -i 's|<Route path="/" element={<Start />} />|<Route path="/" element={<ExcalidrawApp />} />|' excalidraw-app/index.tsx \
 && grep -q 'path="/" element={<ExcalidrawApp />}' excalidraw-app/index.tsx
ARG NODE_ENV=production
RUN yarn build:app:docker

FROM nginxinc/nginx-unprivileged:1.29-alpine
COPY shineori/default.conf /etc/nginx/conf.d/default.conf
COPY --from=build /opt/node_app/excalidraw-app/build /usr/share/nginx/html
