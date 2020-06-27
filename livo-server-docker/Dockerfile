FROM java:openjdk-7-jre
MAINTAINER Deniz Acay <deniz@livomobile.com>

ADD distribution-1.0.0-bin.tar.gz /srv/livod/

RUN mkdir -p /var/opt/livod/

ENV AEON_HOME /var/opt/livod/

VOLUME /var/opt/livod/

WORKDIR /srv/livod/

EXPOSE 2366 6667

ENTRYPOINT java -Duser.language=en -Duser.country=US -Dcom.sun.management.jmxremote=true -Dcom.sun.management.jmxremote.port=6667 -Dcom.sun.management.jmxremote.authenticate=false -Dcom.sun.management.jmxremote.ssl=false -jar bin/felix.jar
