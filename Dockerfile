# spring boot admin
FROM openjdk:17-slim-buster as build-springadmin
WORKDIR spring-boot-admin
COPY ./spring-boot-admin/.mvn .mvn
COPY ./spring-boot-admin/mvnw .
COPY ./spring-boot-admin/pom.xml .
RUN ./mvnw -B dependency:go-offline
COPY ./spring-boot-admin/src src
RUN ./mvnw -B package                                    
FROM openjdk:17-slim-buster

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
WORKDIR /usr/share/nginx/html

RUN apk add openjdk17
RUN apk add --no-cache nodejs npm
RUN npm install -g @beam-australia/react-env@3.1.1
ADD customer-management-frontend/.env ./
ADD customer-management-frontend/entrypoint.sh /var/entrypoint.sh

# ENV SPRING_BOOT_ADMIN_CLIENT_URL https://lakesidemutual-production.up.railway.app:9000
# ENV CUSTOMERCORE_BASEURL https://lakesidemutual-production.up.railway.app:8110
# ENV REACT_APP_CUSTOMER_MANAGEMENT_BACKEND https://lakesidemutual-production.up.railway.app:8100

COPY --from=build-backend customer-management-backend/target/customer-management-backend-0.0.1-SNAPSHOT.jar .
COPY --from=build-core customer-core/target/customer-core-0.0.1-SNAPSHOT.jar .
COPY --from=build-springadmin spring-boot-admin/target/spring-boot-admin-0.0.1-SNAPSHOT.jar .

EXPOSE 80 3020 8100 8110 9000

ADD root-entrypoint.sh /var/root-entrypoint.sh
RUN chmod +x /var/root-entrypoint.sh
ENTRYPOINT ["/var/root-entrypoint.sh"]

CMD ["nginx", "-g", "daemon off;"]
