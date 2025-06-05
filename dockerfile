FROM node:22-alpine
WORKDIR /app
COPY package*.json yarn.lock ./
RUN yarn install --frozen-lockfile && yarn cache clean
EXPOSE 4000
COPY . .
RUN yarn build