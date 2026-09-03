import { KafkaConfig } from "kafkajs";

const eventHubsKafkaPort = 9093;

export function createKafkaConfig(
  clientId: string,
  brokers: string[],
  connectionString: string
): KafkaConfig {
  const config: KafkaConfig = {
    clientId,
    brokers,
    retry: {
      initialRetryTime: 3000,
      retries: 15
    }
  };

  if (!connectionString) {
    return config;
  }

  return {
    ...config,
    brokers: [eventHubsBroker(connectionString)],
    ssl: true,
    sasl: {
      mechanism: "plain",
      username: "$ConnectionString",
      password: connectionString
    }
  };
}

export function eventHubsBroker(connectionString: string): string {
  const endpointEntry = connectionString
    .split(";")
    .map((entry) => entry.split(/=(.*)/s, 2))
    .find(([key]) => key.trim().toLowerCase() === "endpoint");
  const endpoint = endpointEntry?.[1]?.trim();
  if (!endpoint) {
    throw new Error("Kafka connection string is missing Endpoint");
  }

  const parsedEndpoint = new URL(endpoint);
  if (parsedEndpoint.protocol !== "sb:" || !parsedEndpoint.hostname) {
    throw new Error("Kafka Endpoint must be an sb:// URL");
  }

  return `${parsedEndpoint.hostname}:${eventHubsKafkaPort}`;
}
