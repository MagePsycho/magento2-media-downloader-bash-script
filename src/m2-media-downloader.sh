#!/bin/bash

#
# Script to download the media files for Magento 2
#
# @author   Raj KB <magepsycho@gmail.com>
# @website  https://www.magepsycho.com
# @version  1.0.0

# Exit on error. Append "|| true" if you expect an error.
#set -o errexit
# Exit on error inside any functions or subshells.
#set -o errtrace
# Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
#set -o nounset
# Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump | gzip`
#set -o pipefail
# Turn on traces, useful while debugging but commented out by default
# set -o xtrace

################################################################################
# CORE FUNCTIONS - Do not edit
################################################################################
#
# VARIABLES
#
_bold=$(tput bold)
_italic="\e[3m"
_underline=$(tput sgr 0 1)
_reset=$(tput sgr0)

_black=$(tput setaf 0)
_purple=$(tput setaf 171)
_red=$(tput setaf 1)
_green=$(tput setaf 76)
_tan=$(tput setaf 3)
_blue=$(tput setaf 38)
_white=$(tput setaf 7)

#
# HEADERS & LOGGING
#
function _debug()
{
    if [[ "$DEBUG" -eq 1 ]]; then
        "$@"
    fi
}

function _header()
{
    printf '\n%s%s==========  %s  ==========%s\n' "$_bold" "$_purple" "$@" "$_reset"
}

function _arrow()
{
    printf '➜ %s\n' "$@"
}

function _success()
{
    printf '%s✔ %s%s\n' "$_green" "$@" "$_reset"
}

function _error() {
    printf '%s✖ %s%s\n' "$_red" "$@" "$_reset"
}

function _warning()
{
    printf '%s➜ %s%s\n' "$_tan" "$@" "$_reset"
}

function _underline()
{
    printf '%s%s%s%s\n' "$_underline" "$_bold" "$@" "$_reset"
}

function _bold()
{
    printf '%s%s%s\n' "$_bold" "$@" "$_reset"
}

function _note()
{
    printf '%s%s%sNote:%s %s%s%s\n' "$_underline" "$_bold" "$_blue" "$_reset" "$_blue" "$@" "$_reset"
}

function _die()
{
    _error "$@"
    exit 1
}

function _safeExit()
{
    exit 0
}

#
# UTILITY HELPER
#
function _seekValue()
{
    local _msg="${_green}$1${_reset}"
    local _readDefaultValue="$2"
    READVALUE=
    if [[ "${_readDefaultValue}" ]]; then
        _msg="${_msg} ${_white}[${_reset}${_green}${_readDefaultValue}${_reset}${_white}]${_reset}"
    else
        _msg="${_msg} ${_white}[${_reset} ${_white}]${_reset}"
    fi

    _msg="${_msg}: "
    printf "$_msg\n➜ "
    read READVALUE

    # Inline input
    #_msg="${_msg}: "
    #read -r -p "$_msg" READVALUE

    if [[ $READVALUE = [Nn] ]]; then
        READVALUE=''
        return
    fi
    if [[ -z "${READVALUE}" ]] && [[ "${_readDefaultValue}" ]]; then
        READVALUE=${_readDefaultValue}
    fi
}

function _seekConfirmation()
{
    read -r -p "${_bold}${1:-Are you sure? [y/N]}${_reset} " response
    case "$response" in
        [yY][eE][sS]|[yY])
            retval=0
            ;;
        *)
            retval=1
            ;;
    esac
    return $retval
}

# Test whether the result of an 'ask' is a confirmation
function _isConfirmed()
{
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        return 0
    fi
    return 1
}

function _typeExists()
{
    if type "$1" >/dev/null; then
        return 0
    fi
    return 1
}

function _isOs()
{
    if [[ "${OSTYPE}" == $1* ]]; then
      return 0
    fi
    return 1
}

function _isOsDebian()
{
    if [[ -f /etc/debian_version ]]; then
        return 0
    else
        return 1
    fi
}

function _checkRootUser()
{
    #if [ "$(id -u)" != "0" ]; then
    if [ "$(whoami)" != 'root' ]; then
        echo "You have no permission to run $0 as non-root user. Use sudo"
        exit 1;
    fi
}

function _semVerToInt() {
  local _sem_ver
  _sem_ver="${1:?No version number supplied}"
  _sem_ver="${_sem_ver//[^0-9.]/}"
  # shellcheck disable=SC2086
  set -- ${_sem_ver//./ }
  printf -- '%d%02d%02d' "${1}" "${2:-0}" "${3:-0}"
}

function _selfUpdate()
{
    local _tmpFile=$(mktemp -p "" "XXXXX.sh")
    curl -s -L "$SCRIPT_URL" > "$_tmpFile" || _die "Couldn't download the file"
    local _newVersion=$(awk -F'[="]' '/^VERSION=/{print $3}' "$_tmpFile")
    if [[ "$(_semVerToInt $VERSION)" < "$(_semVerToInt $_newVersion)" ]]; then
        printf "Updating script \e[31;1m%s\e[0m -> \e[32;1m%s\e[0m\n" "$VERSION" "$_newVersion"
        printf "(Run command: %s --version to check the version)" "$(basename "$0")"
        mv -v "$_tmpFile" "$ABS_SCRIPT_PATH" || _die "Unable to update the script"
        # rm "$_tmpFile" || _die "Unable to clean the temp file: $_tmpFile"
        # @todo make use of trap
        # trap "rm -f $_tmpFile" EXIT
    else
         _arrow "Already the latest version."
    fi
    exit 1
}

function _printPoweredBy()
{
    local mp_ascii
    mp_ascii='
   __  ___              ___               __
  /  |/  /__ ____ ____ / _ \___ __ ______/ /  ___
 / /|_/ / _ `/ _ `/ -_) ___(_-</ // / __/ _ \/ _ \
/_/  /_/\_,_/\_, /\__/_/  /___/\_, /\__/_//_/\___/
            /___/             /___/
'
    cat <<EOF
${_green}
Powered By:
$mp_ascii

 >> Store: ${_reset}${_underline}${_blue}https://www.magepsycho.com${_reset}${_reset}${_green}
 >> Blog:  ${_reset}${_underline}${_blue}https://blog.magepsycho.com${_reset}${_reset}${_green}

################################################################
${_reset}
EOF
}

################################################################################
# SCRIPT FUNCTIONS
################################################################################
function _printVersion()
{
    echo "Version $VERSION"
    exit 1
}

function _printUsage()
{
    echo -n -e "$(basename "$0") [OPTION]...

Script to download the media files for Magento 2
Version $VERSION

    Options:
        -t,     --type             Entity Type (category|product)
        -i,     --id               Entity ID
        -h,     --help             Display this help and exit
        -dr     --dry-run          Show what would have been transferred
        -d,     --debug            Enable the debug mode (set -x)
        -v,     --version          Output version information and exit
        -u,     --update           Self-update the script from Git repository
                --self-update      Self-update the script from Git repository

    Examples:
        $(basename "$0") --type=... --id=... [--dry-run] [--debug] [--version] [--self-update] [--help]

$(tput setaf 136)For SSH params, it's recommended to use the config file (~/${CONFIG_FILE} or ./${CONFIG_FILE})${_reset}
"
    _printPoweredBy
    exit 1
}

function checkCmdDependencies()
{
    local _dependencies=(
      rsync
      ssh
      sed
      wget
      curl
      awk
      mysql
      php
    )

    for cmd in "${_dependencies[@]}"
    do
        hash "${cmd}" &>/dev/null || _die "'${cmd}' command not found."
    done;
}

function processArgs()
{
    # Parse Arguments
    for arg in "$@"
    do
        case $arg in
            -t|--type=*)
                ENTITY_TYPE="${arg#*=}"
            ;;
            -i|--id=*)
                ENTITY_ID="${arg#*=}"
            ;;
            -dr|--dry-run)
                DRY_RUN=1
            ;;
            --debug)
                DEBUG=1
                set -o xtrace
            ;;
            -v|--version)
                _printVersion
            ;;
            -h|--help)
                _printUsage
            ;;
            -u|--update|--self-update)
                _selfUpdate
            ;;
            *)
                #_printUsage
            ;;
        esac
    done

    validateArgs
    sanitizeArgs
}

function initDefaultArgs()
{
    INSTALL_DIR=$(pwd)
}

function assertMage2Directory()
{
    if [[ ! -f './bin/magento' ]] || [[ ! -f './app/etc/di.xml' ]] || [[ ! -f './app/etc/env.php' ]]; then
        _die "Please run the command from Magento 2 root directory."
    fi
}

function loadConfigValues()
{
    # Load config if exists in home(~/)
    if [[ -f "$HOME/${CONFIG_FILE}" ]]; then
        source "$HOME/${CONFIG_FILE}"
    fi

    # Load config if exists in project (./)
    if [[ -f "${INSTALL_DIR}/${CONFIG_FILE}" ]]; then
        source "${INSTALL_DIR}/${CONFIG_FILE}"
    fi
}

function sanitizeArgs()
{
    # remove trailing /
    if [[ ! -z "$SSH_M2_ROOT_DIR" ]]; then
        SSH_M2_ROOT_DIR="${SSH_M2_ROOT_DIR%/}"
    fi
}

function validateArgs()
{
    ERROR_COUNT=0

    if [[ -z "$ENTITY_TYPE" ]]; then
        _error "Entity type (--type=...) cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ ! -z "$ENTITY_TYPE" && "$ENTITY_TYPE" != @(category|product) ]]; then
        _error "Entity type (--type=...) is not valid. Supported: category|product"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$ENTITY_ID" ]]; then
        _error "Entity ID (--id=...) cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ ! -z "$ENTITY_ID" ]]  && [[ -z "${ENTITY_ID##*[!0-9]*}" ]]; then
        _error "Entity ID (--id=...) is not valid"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$SSH_HOST" ]]; then
        _error "SSH_HOST param cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$SSH_USER" ]]; then
        _error "SSH_USER param cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

    if [[ -z "$SSH_M2_ROOT_DIR" ]]; then
        _error "SSH_M2_ROOT_DIR param cannot be empty"
        ERROR_COUNT=$((ERROR_COUNT + 1))
    fi

# @todo Check why it's not working
#    if [[ -z "$SSH_HOST" || -z "$SSH_USER" || $SSH_M2_ROOT_DIR ]]; then
#        _note "Use config file (~/${CONFIG_FILE} or ./${CONFIG_FILE})"
#        ERROR_COUNT=$((ERROR_COUNT + 1))
#    fi

    #echo "$ERROR_COUNT"
    [[ "$ERROR_COUNT" -gt 0 ]] && exit 1
}

function prepareDBParams()
{
    eval "$(php -r '
      $env = include "./app/etc/env.php";
      echo "declare -A config=()\n";
      echo "config[db.prefix]=" . escapeshellarg($env["db"]["table_prefix"]) . "\n";
      echo "config[db.host]=" . escapeshellarg($env["db"]["connection"]["default"]["host"]) . "\n";
      echo "config[db.username]=" . escapeshellarg($env["db"]["connection"]["default"]["username"]) . "\n";
      echo "config[db.password]=" . escapeshellarg($env["db"]["connection"]["default"]["password"]) . "\n";
      echo "config[db.dbname]=" . escapeshellarg($env["db"]["connection"]["default"]["dbname"]) . "\n";
    ')"

    DB_PREFIX="${config[db.prefix]}"
    DB_HOST="${config[db.host]}"
    DB_USER="${config[db.username]}"
    DB_PASS="${config[db.password]}"
    DB_NAME="${config[db.dbname]}"
}

function queryMysql()
{
   mysql -h ${DB_HOST} -u ${DB_USER} --password="${DB_PASS}" ${DB_NAME} --execute="${SQL_QUERY}"
}

function getImages()
{
    local _results _images
    SQL_QUERY="SELECT DISTINCT cpev.value FROM catalog_product_entity e INNER JOIN catalog_category_product ccp ON e.entity_id = ccp.product_id INNER JOIN catalog_category_entity cce ON ccp.category_id = cce.entity_id INNER JOIN catalog_product_entity_varchar cpev ON e.entity_id = cpev.entity_id INNER JOIN eav_attribute ea ON cpev.attribute_id = ea.attribute_id AND ea.attribute_code IN ('image', 'thumbnail', 'small_image') AND ea.entity_type_id = 4 WHERE ccp.category_id = '${ENTITY_ID}'";
    queryMysql
}

function downloadMediaFiles()
{
    local _images _rsReturn _sshPrivateKeyParam _dryRunParam

    _images=( $( for i in $(getImages) ; do if [[ "$i" != 'value' ]]; then echo $i; fi done ) )

    _arrow "Downloading media files (${#_images[@]})..."
    # Remote connect and download those images
    if [[ ! -z "$SSH_PRIVATE_KEY" ]]; then
        _sshPrivateKeyParam=" -i $SSH_PRIVATE_KEY"
    fi

    # declare -a _images=( "/1/-/1-m2-region-city-dropdown-admin-menu.png" "/2/-/2-m2-region-city-dropdown-general-settings.png" )

    # @todo handle --dry-run
    if [[ "$DRY_RUN" -eq 1 ]]; then
        _dryRunParam=" --dry-run"
    fi
    rsync -ravz --files-from=<( printf "%s\n" "${_images[@]}" ) -e "ssh -p ${SSH_PORT}${_sshPrivateKeyParam}" --progress --stats "${SSH_USER}"@"${SSH_HOST}":"${SSH_M2_ROOT_DIR}"/pub/media/catalog/"${ENTITY_TYPE}"/ ./pub/media/catalog/"${ENTITY_TYPE}"/
    _rsReturn=$?
    if [[ "$_rsReturn" -ne 0 ]]; then
        _die "Could not download media files. Please check your SSH settings or media directory permissions."
    fi
}

function initUserInputWizard()
{
    :
}

function printSuccessMessage()
{
    _success "Images have been successfully downloaded."

    echo "################################################################"
    echo " >> Entity Type           : ${ENTITY_TYPE}"
    echo " >> Entity ID             : ${ENTITY_ID}"
    echo " >> Downloaded Dir        : ${INSTALL_DIR}/pub/media/"
    echo "################################################################"
    _printPoweredBy
}

################################################################################
# Main
################################################################################
export LC_CTYPE=C
export LANG=C

DEBUG=0
_debug set -x
VERSION="1.0.0"
SCRIPT_URL='https://raw.githubusercontent.com/MagePsycho/magento2-media-downloader-bash-script/main/src/m2-media-downloader.sh'
SCRIPT_LOCATION="${BASH_SOURCE[@]}"
ABS_SCRIPT_PATH=$(readlink -f "$SCRIPT_LOCATION")

CONFIG_FILE=".m2media_ssh.conf"
DRY_RUN=0
INSTALL_DIR=
ENTITY_TYPE=
ENTITY_ID=

# DB
DB_PREFIX=
DB_HOST=
DB_USER=
DB_PASS=
DB_NAME=

# SSH
SSH_PRIVATE_KEY=
SSH_HOST=
SSH_PORT=22
SSH_USER=
SSH_M2_ROOT_DIR=

function main()
{
    checkCmdDependencies

    [[ $# -lt 1 ]] && _printUsage

    assertMage2Directory
    initDefaultArgs
    loadConfigValues

    processArgs "$@"

    prepareDBParams
    downloadMediaFiles

    printSuccessMessage

    exit 0
}

main "$@"

_debug set +x
