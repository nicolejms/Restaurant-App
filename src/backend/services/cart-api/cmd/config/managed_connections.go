package config

import (
	"crypto/tls"
	"fmt"
	"net"
	"net/url"
	"strings"
	"time"

	"github.com/IBM/sarama"
	"github.com/redis/go-redis/v9"
)

const eventHubsKafkaPort = "9093"

func RedisOptions(host, connectionURL string) (*redis.Options, error) {
	if connectionURL != "" {
		options, err := redis.ParseURL(connectionURL)
		if err != nil {
			return nil, fmt.Errorf("parse Redis connection URL: %w", err)
		}
		return options, nil
	}

	if host == "" {
		host = ":6379"
	}
	return &redis.Options{Addr: host}, nil
}

func KafkaClientConfig(broker, connectionString string) ([]string, *sarama.Config, error) {
	clientConfig := sarama.NewConfig()
	clientConfig.Consumer.Offsets.AutoCommit.Enable = true
	clientConfig.Consumer.Offsets.AutoCommit.Interval = time.Second

	if connectionString == "" {
		if broker == "" {
			return nil, nil, fmt.Errorf("Kafka broker or connection string is required")
		}
		return []string{broker}, clientConfig, nil
	}

	eventHubsBroker, err := eventHubsBroker(connectionString)
	if err != nil {
		return nil, nil, err
	}

	clientConfig.Version = sarama.V1_0_0_0
	clientConfig.Net.SASL.Enable = true
	clientConfig.Net.SASL.Mechanism = sarama.SASLTypePlaintext
	clientConfig.Net.SASL.User = "$ConnectionString"
	clientConfig.Net.SASL.Password = connectionString
	clientConfig.Net.TLS.Enable = true
	clientConfig.Net.TLS.Config = &tls.Config{MinVersion: tls.VersionTLS12}

	return []string{eventHubsBroker}, clientConfig, nil
}

func eventHubsBroker(connectionString string) (string, error) {
	var endpoint string
	for _, part := range strings.Split(connectionString, ";") {
		key, value, found := strings.Cut(part, "=")
		if found && strings.EqualFold(strings.TrimSpace(key), "Endpoint") {
			endpoint = strings.TrimSpace(value)
			break
		}
	}
	if endpoint == "" {
		return "", fmt.Errorf("Kafka connection string is missing Endpoint")
	}

	parsedEndpoint, err := url.Parse(endpoint)
	if err != nil {
		return "", fmt.Errorf("parse Kafka Endpoint: %w", err)
	}
	if !strings.EqualFold(parsedEndpoint.Scheme, "sb") || parsedEndpoint.Hostname() == "" {
		return "", fmt.Errorf("Kafka Endpoint must be an sb:// URL")
	}

	return net.JoinHostPort(parsedEndpoint.Hostname(), eventHubsKafkaPort), nil
}
