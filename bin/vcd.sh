#!/usr/bin/env bash

cmd="${1-help}"

vcd_server_url='http://localhost:9000'

case "$cmd" in
help|--help)
    echo "commands: "
    echo "  vcd hola foo/bar '{...json hash...}' -- dispatches the hash to the foo/bar bucket on the  vayacondios server"
    echo "  vcd help                             -- this text"
    echo ""
    echo "example: "
    echo "  $0 hola just/fiddlin '{\"hi\":\"there\"}'"
    echo ""
    ;;

hola)
    bucket="$2"
    facts="$3"
    if [ -z "$bucket" ] || [ -z "$facts" ] ; then echo "vcd hola foo/bar '{...json hash...}'" ; echo "  got '$bucket' '$fact'" ; exit -1 ; fi

    echo -- curl -H 'Content-Type:application/json' -d "'$facts'" "'$vcd_server_url/$bucket'"
    curl -H 'Content-Type:application/json' -d "$facts" "$vcd_server_url/$bucket"
    ;;

esac
