# Dockerfile for aws-elastic-beanstalk-express-js-sample

# use node.js 16 as the base image
FROM node:16

# set working directory inside the container
WORKDIR /usr/src/app

# copy package file
COPY package*.json ./

# install dependencies
RUN npm install

# copy the remaining code
COPY . .

# expose the port for app as per app.js
EXPOSE 8080

# start app
CMD ["npm","start"]