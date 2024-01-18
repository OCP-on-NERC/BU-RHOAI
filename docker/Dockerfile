FROM quay.io/operate-first/opf-toolbox:v0.8.0
RUN dnf -y update
RUN dnf -y install jq
WORKDIR /shell-scripts
COPY src/* /shell-scripts
CMD ["/bin/sh"]