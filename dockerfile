FROM node:22-alpine as build

WORKDIR /usr/src/app

COPY package.json  yarn.lock  ./

RUN yarn

COPY . .

RUN yarn build
RUN yarn install --production --frozen-lockfile && yarn cache clean

FROM node:22-alpine3.23

WORKDIR /usr/src/app
COPY --from=build /usr/src/app/package.json ./package.json
COPY --from=build /usr/src/app/dist ./dist
COPY --from=build /usr/src/app/node_modules ./node_modules

EXPOSE 3000

CMD [ "yarn", "start:prod" ]