FROM hashicorp/terraform:latest

WORKDIR /terraform
COPY providers.tf terraform.tf /terraform/
COPY *.sh /
VOLUME /state

RUN terraform init
ENTRYPOINT []
CMD ["local.sh"]
