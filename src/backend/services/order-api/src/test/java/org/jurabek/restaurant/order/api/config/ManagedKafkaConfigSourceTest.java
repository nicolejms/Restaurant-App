package org.jurabek.restaurant.order.api.config;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;

import org.junit.jupiter.api.Test;

class ManagedKafkaConfigSourceTest {
    private static final String CONNECTION_STRING =
        "Endpoint=sb://restaurant.servicebus.windows.net/;"
            + "SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=test-key";

    @Test
    void configuresAzureEventHubsKafkaAuthentication() {
        ManagedKafkaConfigSource source = new ManagedKafkaConfigSource(
            Map.of("CONNECTION_KAFKA_CONNECTIONSTRING", CONNECTION_STRING)
        );

        assertEquals(
            "restaurant.servicebus.windows.net:9093",
            source.getValue("kafka.bootstrap.servers")
        );
        assertEquals("SASL_SSL", source.getValue("kafka.security.protocol"));
        assertEquals("PLAIN", source.getValue("kafka.sasl.mechanism"));
        assertTrue(source.getValue("kafka.sasl.jaas.config").contains(CONNECTION_STRING));
    }

    @Test
    void leavesLocalKafkaConfigurationUnchangedWithoutConnectionString() {
        ManagedKafkaConfigSource source = new ManagedKafkaConfigSource(Map.of());

        assertTrue(source.getProperties().isEmpty());
    }
}
