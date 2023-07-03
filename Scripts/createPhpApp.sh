#!/bin/bash

set -e

check_docker_running() {
    docker info > /dev/null 2>&1 || (echo "Docker is not running."; exit 1)
}

create_laravel_app() {
    local app_name=$1

    docker run --rm \
        --pull=always \
        -u $(id -u):$(id -g) \
        -v "$(pwd)":/opt \
        -w /opt \
        laravelsail/php82-composer:latest \
        bash -c "laravel new $app_name && cd $app_name && php ./artisan sail:install --with=mysql,redis,meilisearch,mailpit,selenium"
}

create_symfony_app() {
    local app_name=$1

    docker run --rm \
        --pull=always \
        -u $(id -u):$(id -g) \
        -v "$(pwd)":/opt \
        -w /opt \
        composer:2 \
        bash -c "composer create-project symfony/website-skeleton $app_name"
}

prompt_for_app_type() {
    local app_name=$1

    echo "Choose the type of application to create:"
    echo "1. Laravel"
    echo "2. Symfony"
    read -p "Enter your choice (1 or 2): " app_type

    case $app_type in
        1) create_laravel_app $app_name ;;
        2) create_symfony_app $app_name ;;
        *) echo "Invalid choice. Exiting." && exit 1 ;;
    esac
}

create_application() {
    local app_type=$1
    local app_name=$2

    case $app_type in
        laravel) create_laravel_app $app_name ;;
        symfony) create_symfony_app $app_name ;;
        *) echo "Invalid app type. Exiting." && exit 1 ;;
    esac
}

parse_command_line_args() {
    local app_type=""
    local app_name=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            --laravel) app_type="laravel" ;;
            --symfony) app_type="symfony" ;;
            *) app_name=$1 ;;
        esac
        shift
    done

    if [ -z "$app_type" ] || [ -z "$app_name" ]; then
        echo "Invalid command-line arguments. Exiting."
        exit 1
    fi

    create_application $app_type $app_name
}

handle_user_input() {
    local app_name=""

    read -p "Enter the name of your project: " app_name
    prompt_for_app_type $app_name
}

main() {
    check_docker_running

    if [ $# -eq 0 ]; then
        handle_user_input
    else
        parse_command_line_args "$@"
    fi

    cd "$app_name"

    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m'

    echo ""

    echo -e "${BOLD}Get started with:${NC} cd \"$app_name\""
}

main "$@"
