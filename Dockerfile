FROM node:latest

WORKDIR /app
COPY . .
EXPOSE 3000

RUN npm install express
RUN npm install

CMD ["node", "index.js"]