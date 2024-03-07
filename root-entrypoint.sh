#!/bin/sh

java -jar customer-core-0.0.1-SNAPSHOT.jar

java -jar customer-management-backend-0.0.1-SNAPSHOT.jar

java -jar spring-boot-admin-0.0.1-SNAPSHOT.jar

set -e
echo "Serializing environment:"
react-env --dest .
cat __ENV.js
exec "$@"
