# customer core
FROM openjdk:17-slim-buster as build-core
WORKDIR customer-core
COPY ./customer-core/.mvn .mvn
COPY ./customer-core/mvnw .
COPY ./customer-core/pom.xml .

RUN ./mvnw -B dependency:go-offline                          

COPY ./customer-core/src src

RUN ./mvnw -B package                                        

FROM openjdk:17-slim-buster

# COPY --from=build-core customer-core/target/customer-core-0.0.1-SNAPSHOT.jar .

# EXPOSE 8110

# ENTRYPOINT ["java", "-jar", "customer-core-0.0.1-SNAPSHOT.jar"]

# customer-management-backend
FROM openjdk:17-slim-buster as build-backend
WORKDIR customer-management-backend

COPY ./customer-management-backend/.mvn .mvn
COPY ./customer-management-backend/mvnw .
COPY ./customer-management-backend/pom.xml .

RUN ./mvnw -B dependency:go-offline                          

COPY ./customer-management-backend/src src

RUN ./mvnw -B package                                        

FROM openjdk:17-slim-buster

# COPY --from=build-backend customer-management-backend/target/customer-management-backend-0.0.1-SNAPSHOT.jar .

# EXPOSE 8100

# ENTRYPOINT ["java", "-jar", "customer-management-backend-0.0.1-SNAPSHOT.jar"]

# customer-management-frontend
FROM node:16 as build-frontend
WORKDIR /usr/src/app
COPY customer-management-frontend/package.json ./
COPY customer-management-frontend/package-lock.json ./
RUN npm install
COPY customer-management-frontend ./
RUN npm run build

FROM nginx:stable-alpine
COPY customer-management-frontend/nginx.vh.default.conf /etc/nginx/conf.d/default.conf
COPY --from=build-frontend /usr/src/app/build /usr/share/nginx/html
# EXPOSE 80
WORKDIR /usr/share/nginx/html

RUN apk add --no-cache nodejs npm
RUN npm install -g @beam-australia/react-env@3.1.1
ADD customer-management-frontend/.env ./
ADD customer-management-frontend/entrypoint.sh /var/entrypoint.sh

COPY --from=build-backend customer-management-backend/target/customer-management-backend-0.0.1-SNAPSHOT.jar .
COPY --from=build-core customer-core/target/customer-core-0.0.1-SNAPSHOT.jar .

EXPOSE 80 8110 8100

ENTRYPOINT ["root-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]

