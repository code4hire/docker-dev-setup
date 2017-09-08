FROM alpine:3.5

LABEL maintainer Srdjan Vranac <vranac@gmail.com>

ARG NGINX_PROJECT_ROOT="/application/web"
ARG NGINX_ENTRY_POINT_FILE="app_dev.php"
ARG NGINX_ALLOWED_FILES="app|app_dev|config"

RUN apk add --update nginx && rm -rf /var/cache/apk/*

ADD ./nginx.conf /etc/nginx/nginx.conf

ADD ./application-dev-7.1.conf \
    ./application-dev-7.0.conf \
    ./application-dev-5.6.conf \
    /etc/nginx/conf.d/

RUN /bin/sed -i "s@\${PROJECT_ROOT}@$NGINX_PROJECT_ROOT@" /etc/nginx/conf.d/application*.conf \
    && /bin/sed -i "s@\${ENTRY_POINT_FILE}@$NGINX_ENTRY_POINT_FILE@" /etc/nginx/conf.d/application*.conf \
    && /bin/sed -i "s@\${ALLOWED_FILES}@$NGINX_ALLOWED_FILES@" /etc/nginx/conf.d/application*.conf

RUN mkdir -p /var/log/nginx

EXPOSE 8071 8070 8056

CMD ["nginx"]
