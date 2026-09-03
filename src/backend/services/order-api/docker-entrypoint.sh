#!/bin/sh
set -eu

connection_string_host() {
  connection_string=$1
  endpoint=
  old_ifs=$IFS
  IFS=';'
  for entry in $connection_string; do
    case "$entry" in
      Endpoint=*)
        endpoint=${entry#Endpoint=}
        break
        ;;
    esac
  done
  IFS=$old_ifs

  case "$endpoint" in
    sb://*.servicebus.windows.net | sb://*.servicebus.windows.net/)
      host=${endpoint#sb://}
      printf '%s:9093' "${host%/}"
      ;;
    *)
      echo "Kafka connection string must contain an Event Hubs sb:// Endpoint" >&2
      return 1
      ;;
  esac
}

shared_connection_string=${KAFKA_CONNECTION_STRING:-${CONNECTION_KAFKA_CONNECTIONSTRING:-}}
checkout_connection_string=${CONNECTION_CHECKOUTKAFKA_CONNECTIONSTRING:-$shared_connection_string}
orders_connection_string=${CONNECTION_ORDERSKAFKA_CONNECTIONSTRING:-$shared_connection_string}

set -- \
  java \
  -Dquarkus.http.host=0.0.0.0 \
  -Djava.util.logging.manager=org.jboss.logmanager.LogManager

if [ -n "$checkout_connection_string" ]; then
  checkout_host=$(connection_string_host "$checkout_connection_string")
  set -- "$@" \
    "-Dmp.messaging.incoming.checkout.bootstrap.servers=$checkout_host" \
    -Dmp.messaging.incoming.checkout.security.protocol=SASL_SSL \
    -Dmp.messaging.incoming.checkout.sasl.mechanism=PLAIN \
    "-Dmp.messaging.incoming.checkout.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"\$ConnectionString\" password=\"$checkout_connection_string\";"
fi

if [ -n "$orders_connection_string" ]; then
  orders_host=$(connection_string_host "$orders_connection_string")
  set -- "$@" \
    "-Dmp.messaging.outgoing.order-completed.bootstrap.servers=$orders_host" \
    -Dmp.messaging.outgoing.order-completed.security.protocol=SASL_SSL \
    -Dmp.messaging.outgoing.order-completed.sasl.mechanism=PLAIN \
    "-Dmp.messaging.outgoing.order-completed.sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username=\"\$ConnectionString\" password=\"$orders_connection_string\";"
fi

exec "$@" -jar ./application
