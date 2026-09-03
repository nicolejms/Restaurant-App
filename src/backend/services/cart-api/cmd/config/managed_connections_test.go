package config

import (
	"testing"

	"github.com/IBM/sarama"
	"github.com/stretchr/testify/require"
)

const testEventHubsConnectionString = "Endpoint=sb://restaurant.servicebus.windows.net/;SharedAccessKeyName=RootManageSharedAccessKey;SharedAccessKey=test-key"

func TestRedisOptionsFromURL(t *testing.T) {
	options, err := RedisOptions("", "rediss://default:test-key@redis.example.com:10000")

	require.NoError(t, err)
	require.Equal(t, "redis.example.com:10000", options.Addr)
	require.Equal(t, "default", options.Username)
	require.Equal(t, "test-key", options.Password)
	require.True(t, options.TLSConfig != nil)
}

func TestKafkaClientConfigFromEventHubsConnectionString(t *testing.T) {
	brokers, clientConfig, err := KafkaClientConfig("", testEventHubsConnectionString)

	require.NoError(t, err)
	require.Equal(t, []string{"restaurant.servicebus.windows.net:9093"}, brokers)
	require.True(t, clientConfig.Net.SASL.Enable)
	require.Equal(t, sarama.SASLMechanism(sarama.SASLTypePlaintext), clientConfig.Net.SASL.Mechanism)
	require.Equal(t, "$ConnectionString", clientConfig.Net.SASL.User)
	require.Equal(t, testEventHubsConnectionString, clientConfig.Net.SASL.Password)
	require.True(t, clientConfig.Net.TLS.Enable)
}

func TestKafkaClientConfigPreservesPlaintextBroker(t *testing.T) {
	brokers, clientConfig, err := KafkaClientConfig("broker:29092", "")

	require.NoError(t, err)
	require.Equal(t, []string{"broker:29092"}, brokers)
	require.False(t, clientConfig.Net.SASL.Enable)
	require.False(t, clientConfig.Net.TLS.Enable)
}
