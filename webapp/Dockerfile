FROM node:22-alpine3.19 AS builder

WORKDIR /
COPY ./webapp/ /webapp/
# COPY .env.production ./webapp/.env.production
COPY .env.production .env.production
# COPY .env ./webapp/.env
COPY .env .env

RUN cd webapp && npm ci && npm run build

FROM nginx:1.27-alpine
COPY --from=builder /webapp/dist /app
COPY webapp/nginx.default.conf /etc/nginx/conf.d/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
