FROM node:22-alpine3.19 as builder

WORKDIR /webapp/
COPY . /webapp/
COPY .env.production ./
RUN npm ci && npm run build

FROM nginx:1.27-alpine
COPY --from=builder /webapp/dist /app
COPY nginx.default.conf /etc/nginx/conf.d/

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]