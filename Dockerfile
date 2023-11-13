FROM node:latest

WORKDIR /app

EXPOSE 3000

CMD ["node", "index.js"]