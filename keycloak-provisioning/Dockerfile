FROM hashicorp/terraform:1.10

WORKDIR /terraform
COPY providers.tf terraform.tf /terraform/
COPY *.sh /
VOLUME /state
ENV TF_VAR_app_name nplintegrations

RUN terraform init
ENTRYPOINT []
CMD ["local.sh"]
