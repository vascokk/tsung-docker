FROM ubuntu:16.10


ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get dist-upgrade -y --no-install-recommends && \
    apt-get install -y --no-install-recommends software-properties-common

RUN apt-get install -y --no-install-recommends openssh-server gnuplot libtemplate-perl
RUN ssh-keygen -N "" -f /root/.ssh/id_rsa && \
    cp /root/.ssh/id_rsa.pub /root/.ssh/authorized_keys && \
    echo "StrictHostKeyChecking no" >> /root/.ssh/config && \
    echo "UserKnownHostsFile /dev/null" >> /root/.ssh/config

RUN apt-get install -y unzip
RUN apt-get install -y wget
RUN wget https://packages.erlang-solutions.com/erlang-solutions_1.0_all.deb
RUN dpkg -i erlang-solutions_1.0_all.deb
RUN apt-get update
RUN apt-get install -y erlang

# COPY ./erlang_20.0.deb /
# RUN dpkg -i erlang_20.0.deb

RUN apt-get install -y build-essential

COPY ./tsung-master.zip /
RUN unzip tsung-master.zip
WORKDIR /tsung-master/
RUN ./configure
RUN make install


RUN mkdir -p /var/log/tsung && echo "" > /var/log/tsung/tsung.log

COPY ./scripts/tsung-runner.sh /usr/bin/tsung-runner
RUN chmod +x /usr/bin/tsung-runner

EXPOSE 22

# EPMD port: http://www.erlang.org/doc/man/epmd.html#environment_variables
EXPOSE 4369
ENV ERL_EPMD_PORT=4369

# Erlang needs this environment variable
# ENV BINDIR=/usr/lib64/erlang/erts-5.8.5/

EXPOSE 19001-19050
#
# make sure inet_dist_listen_* properties are available when Erlang runs
#
# RUN sed -i.bak s/"64000"/"19001"/g /usr/local/bin/tsung
# RUN sed -i.bak s/"65500"/"19050"/g /usr/local/bin/tsung
# RUN printf "[{kernel,[{inet_dist_listen_min,19001},{inet_dist_listen_max,19050}]}]. \n\n" > /root/sys.config
# RUN sed -i.bak s/"erlexec"/"erlexec -config \/root\/sys "/g /usr/bin/erl

# setup for auto-discovery of the tsung nodes
RUN apt-get install -y --no-install-recommends cron

COPY ./scripts/tsung-update-hosts.sh /usr/local/bin/tsung-update-hosts
RUN chmod +x /usr/local/bin/tsung-update-hosts
RUN mkdir -p /etc/tsung/
RUN echo "* * * * * /usr/local/bin/tsung-update-hosts >> /var/log/tsung/tsung-update-hosts.log 2>&1" > /etc/crontab
RUN touch /var/log/tsung/tsung-update-hosts.log

# mount a location on the disk to access the test scripts
RUN mkdir -p /usr/local/tsung
COPY ./example-test.xml /etc/tsung/
VOLUME ["/usr/local/tsung"]

ENTRYPOINT ["tsung-runner", "-t", "19001", "-T", "19050", "-f", "/etc/tsung/example-test.xml"]



