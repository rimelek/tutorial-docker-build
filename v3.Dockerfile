FROM ubuntu:20.04

ARG app_dir="/app"

ENV version="1.0" \
    config_name=config.ini

RUN mkdir "$app_dir"
RUN echo "version=$version" > "$app_dir/$config_name"

CMD ["env"]