package org.jurabek.restaurant.order.api.config;

import java.net.URI;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.Locale;
import java.util.Map;

import org.eclipse.microprofile.config.spi.ConfigSource;

public final class ManagedKafkaConfigSource implements ConfigSource {
    private static final int ORDINAL = 350;
    private static final String RADIUS_CONNECTION_STRING = "CONNECTION_KAFKA_CONNECTIONSTRING";
    private static final String RADIUS_CHECKOUT_CONNECTION_STRING =
        "CONNECTION_CHECKOUTKAFKA_CONNECTIONSTRING";
    private static final String RADIUS_ORDERS_CONNECTION_STRING =
        "CONNECTION_ORDERSKAFKA_CONNECTIONSTRING";
    private static final String KAFKA_CONNECTION_STRING = "KAFKA_CONNECTION_STRING";

    private final Map<String, String> properties;

    public ManagedKafkaConfigSource() {
        this(System.getenv());
    }

    ManagedKafkaConfigSource(Map<String, String> environment) {
        this.properties = buildProperties(environment);
    }

    @Override
    public Map<String, String> getProperties() {
        return properties;
    }

    @Override
    public String getValue(String propertyName) {
        return properties.get(propertyName);
    }

    @Override
    public String getName() {
        return "managed-kafka";
    }

    @Override
    public int getOrdinal() {
        return ORDINAL;
    }

    private static Map<String, String> buildProperties(Map<String, String> environment) {
        String sharedConnectionString = firstNonBlank(
            environment.get(KAFKA_CONNECTION_STRING),
            environment.get(RADIUS_CONNECTION_STRING));
        String checkoutConnectionString = firstNonBlank(
            environment.get(RADIUS_CHECKOUT_CONNECTION_STRING),
            sharedConnectionString);
        String ordersConnectionString = firstNonBlank(
            environment.get(RADIUS_ORDERS_CONNECTION_STRING),
            sharedConnectionString);
        if (checkoutConnectionString == null && ordersConnectionString == null) {
            return Collections.emptyMap();
        }

        Map<String, String> managedProperties = new LinkedHashMap<>();
        addKafkaProperties(
            managedProperties,
            "mp.messaging.incoming.checkout.",
            checkoutConnectionString);
        addKafkaProperties(
            managedProperties,
            "mp.messaging.outgoing.order-completed.",
            ordersConnectionString);
        return Collections.unmodifiableMap(managedProperties);
    }

    private static void addKafkaProperties(
        Map<String, String> properties,
        String prefix,
        String connectionString
    ) {
        if (connectionString == null) {
            return;
        }

        String endpoint = connectionStringParts(connectionString).get("endpoint");
        if (endpoint == null) {
            throw new IllegalArgumentException("Kafka connection string is missing Endpoint");
        }

        URI endpointUri = URI.create(endpoint);
        if (!"sb".equalsIgnoreCase(endpointUri.getScheme()) || endpointUri.getHost() == null) {
            throw new IllegalArgumentException("Kafka Endpoint must be an sb:// URL");
        }

        properties.put(prefix + "bootstrap.servers", endpointUri.getHost() + ":9093");
        properties.put(prefix + "security.protocol", "SASL_SSL");
        properties.put(prefix + "sasl.mechanism", "PLAIN");
        properties.put(
            prefix + "sasl.jaas.config",
            "org.apache.kafka.common.security.plain.PlainLoginModule required "
                + "username=\"$ConnectionString\" password=\"" + escapeJaas(connectionString) + "\";"
        );
    }

    private static Map<String, String> connectionStringParts(String connectionString) {
        Map<String, String> parts = new LinkedHashMap<>();
        for (String entry : connectionString.split(";")) {
            int separator = entry.indexOf('=');
            if (separator > 0) {
                parts.put(
                    entry.substring(0, separator).trim().toLowerCase(Locale.ROOT),
                    entry.substring(separator + 1).trim()
                );
            }
        }
        return parts;
    }

    private static String escapeJaas(String value) {
        return value.replace("\\", "\\\\").replace("\"", "\\\"");
    }

    private static String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }
}
