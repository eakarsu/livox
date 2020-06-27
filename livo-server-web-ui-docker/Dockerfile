FROM tomcat:8-jre7
MAINTAINER Deniz Acay <deniz@livomobile.com>

RUN rm -rf /usr/local/tomcat/webapps/ROOT

COPY web-ui-1.0.0.war /usr/local/tomcat/webapps/ROOT.war

ENV AEON_HOME /var/opt/livod/

VOLUME /var/opt/livod/
VOLUME /usr/local/tomcat/
