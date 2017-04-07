#!/usr/bin/env bash

# when dealing with multiple php version, might be useful to extract this
xdebug_ext_path="/usr/local/lib/php/extensions/no-debug-non-zts-20160303/xdebug.so"

# source the .env if present
. $PWD/.env

SYNC_CONFIG_SWITCH=" "

if [ ! -z "$DOCKER_SYNC_LOCATION" ]; then
    SYNC_CONFIG_SWITCH=" -c $DOCKER_SYNC_LOCATION"
fi

USE_PHP_VERSION=7.1

if [ ! -z "$PHP_VERSION" ]; then
    USE_PHP_VERSION=$PHP_VERSION
fi

# general functions
call_docker_sync() {
    docker-sync "$@" $SYNC_CONFIG_SWITCH
}

call_docker_sync_daemon() {
    docker-sync-daemon "$@" $SYNC_CONFIG_SWITCH
}

call_docker_compose() {
    docker-compose "$@"
}

call_docker_compose_run() {
    docker-compose run --rm "$@"
}

call_docker_compose_exec() {
    docker-compose exec "$@"
}

# shell
call_php_cli_run_shell() {
    call_docker_compose_run php-cli-$USE_PHP_VERSION /bin/bash
}

call_php_cli_run_shell_command() {
    call_docker_compose_run php-cli-$USE_PHP_VERSION "$@"
}

# php related
call_php_cli() {
    call_docker_compose_run php-cli-$USE_PHP_VERSION "$@"
}

call_php_cli_php() {
    call_docker_compose_run php-cli-$USE_PHP_VERSION /usr/local/bin/php "$@"
}

call_php_cli_php_debug() {
    call_php_cli_php -dzend_extension=${xdebug_ext_path} "$@"
}

call_php_cli_php_profiler() {
    call_docker_compose_run -e XDEBUG_CONFIG="profiler_enable=1" php-cli-$USE_PHP_VERSION /usr/local/bin/php -dzend_extension=${xdebug_ext_path} "$@"
}

call_php_cli_php_console() {
    call_php_cli_php bin/console "$@"
}

# @todo: add test runners for phpunit and phpunit with coverage

# node
call_node() {
    call_docker_compose_run node "$@"
}

call_node_node() {
    call_node /usr/local/bin/node "$@"
}

call_node_npm() {
    call_node /usr/local/bin/npm "$@"
}

call_node_grunt() {
    call_node /usr/local/bin/grunt "$@"
}

call_node_gulp() {
    call_node /usr/local/bin/gulp "$@"
}

call_node_bower() {
    call_node /usr/local/bin/bower "$@"
}

# redis
call_redis() {
    call_docker_compose_exec redis "$@"
}

call_redis_cli() {
    call_redis "redis-cli -h redis -p 6379"
}
