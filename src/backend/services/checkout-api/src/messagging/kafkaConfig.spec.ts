import { expect } from "chai";
import { createKafkaConfig, eventHubsBroker } from "./kafkaConfig";

const connectionString =
  "Endpoint=sb://restaurant.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=test-key";

describe("managed Kafka configuration", () => {
  it("configures Azure Event Hubs Kafka authentication", () => {
    const config = createKafkaConfig("checkout-api", [], connectionString);

    expect(config.brokers).to.deep.equal([
      "restaurant.servicebus.windows.net:9093"
    ]);
    expect(config.ssl).to.equal(true);
    expect(config.sasl).to.deep.equal({
      mechanism: "plain",
      username: "$ConnectionString",
      password: connectionString
    });
  });

  it("preserves plaintext brokers when no connection string is supplied", () => {
    const config = createKafkaConfig("checkout-api", ["broker:29092"], "");

    expect(config.brokers).to.deep.equal(["broker:29092"]);
    expect(config.ssl).to.equal(undefined);
    expect(config.sasl).to.equal(undefined);
  });

  it("rejects connection strings without an Event Hubs endpoint", () => {
    expect(() => eventHubsBroker("SharedAccessKey=test-key")).to.throw(
      "Kafka connection string is missing Endpoint"
    );
  });
});
