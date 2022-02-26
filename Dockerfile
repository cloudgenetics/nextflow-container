ARG VERSION=21.10.0
FROM public.ecr.aws/seqera-labs/nextflow:${VERSION} AS build

# The upstream nextflow containers are based on alpine
# which are not compatible with the aws cli
FROM public.ecr.aws/amazonlinux/amazonlinux:2 AS final
COPY --from=build /usr/local/bin/nextflow /usr/bin/nextflow

RUN yum update -y \
 && yum install -y \
    curl \
    java \
    ncurses-compat-libs \
    procps \    
    unzip \
 && yum clean -y all
RUN rm -rf /var/cache/yum

# install awscli v2
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" \
 && unzip -q /tmp/awscliv2.zip -d /tmp \
 && /tmp/aws/install -i /opt/aws-cli -b /opt/aws-cli/bin\
 && rm -rf /tmp/aws*

ENV PATH="${PATH}:/opt/aws-cli/bin/"
ENV LD_LIBRARY_PATH="/opt/aws-cli/v2/current/dist/${LD_LIBRARY_PATH}"
RUN ln -s /opt/aws-cli/v2/current/dist/libz.so.1 /opt/aws-cli/bin/libz.so.1

ENV JAVA_HOME /usr/lib/jvm/jre-openjdk/

# invoke nextflow once to download dependencies
RUN nextflow -version

# install a custom entrypoint script that handles being run within an AWS Batch Job
COPY nextflow.aws.sh /opt/bin/nextflow.aws.sh
RUN chmod +x /opt/bin/nextflow.aws.sh

# RNA Seq
COPY rnaseq /opt/work/rnaseq
WORKDIR /opt/work
ENTRYPOINT ["/opt/bin/nextflow.aws.sh"]
