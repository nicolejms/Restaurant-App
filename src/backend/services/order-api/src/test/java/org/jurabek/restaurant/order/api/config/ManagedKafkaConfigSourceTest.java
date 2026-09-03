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
            Map.of(
                "CONNECTION_CHECKOUTKAFKA_CONNECTIONSTRING",
                CONNECTION_STRING,
                "CONNECTION_ORDERSKAFKA_CONNECTIONSTRING",
                CONNECTION_STRING.replace("restaurant.", "orders.")
            )
        );

        assertEquals(
            "restaurant.servicebus.windows.net:9093",
            source.getValue("mp.messaging.incoming.checkout.bootstrap.servers")
        );
        assertEquals(
            "orders.servicebus.windows.net:9093",
            source.getValue("mp.messaging.outgoing.order-completed.bootstrap.servers")
        );
        assertEquals(
            "SASL_SSL",
            source.getValue("mp.messaging.incoming.checkout.security.protocol")
        );
        assertEquals(
            "PLAIN",
            source.getValue("mp.messaging.outgoing.order-completed.sasl.mechanism")
        );
        assertTrue(
            source.getValue("mp.messaging.incoming.checkout.sasl.jaas.config")
                .contains(CONNECTION_STRING)
        );
    }

    @Test
    void leavesLocalKafkaConfigurationUnchangedWithoutConnectionString() {
        ManagedKafkaConfigSource source = new ManagedKafkaConfigSource(Map.of());

        assertTrue(source.getProperties().isEmpty());
    }
}
