FROM node:25.8.1-alpine3.23

WORKDIR /app

COPY package.json .
COPY package-lock.json .

RUN npm install --omit=dev

COPY . .

CMD ["npm", "run", "dev"]
