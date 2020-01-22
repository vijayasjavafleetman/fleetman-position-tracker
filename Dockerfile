FROM openjdk:8u131-jre

MAINTAINER Richard Chesterwood "contact@virtualpairprogrammers.com"

ADD positionreceiver.jar webapp.jar

EXPOSE 8080

CMD ["java","-Xmx50m","-jar","webapp.jar"]
