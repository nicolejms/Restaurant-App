package config

import (
	"os"
)

// Configuration injects all environment variables into object
type Configuration struct {
	ServerPort            string
	RedisHost             string
	RedisURL              string
	KafkaBroker           string
	KafkaConnectionString string
	OrdersTopic           string
}

// Init initializes environment variables into config
func Init() *Configuration {
	_ = os.Getenv("PORT")
	var cfg Configuration
	if redisHost, ok := os.LookupEnv("REDIS_HOST"); ok {
		cfg.RedisHost = redisHost
	}
	cfg.RedisURL = firstNonEmpty(
		os.Getenv("REDIS_URL"),
		os.Getenv("CONNECTION_REDIS_URL"),
	)

	if kafkaBroker, ok := os.LookupEnv("KAFKA_BROKER"); ok {
		cfg.KafkaBroker = kafkaBroker
	}
	cfg.KafkaConnectionString = firstNonEmpty(
		os.Getenv("KAFKA_CONNECTION_STRING"),
		os.Getenv("CONNECTION_KAFKA_CONNECTIONSTRING"),
	)

	if ordersTopic, ok := os.LookupEnv("ORDERS_TOPIC"); ok {
		cfg.OrdersTopic = ordersTopic
	}

	return &cfg
}

func firstNonEmpty(values ...string) string {
	for _, value := range values {
		if value != "" {
			return value
		}
	}
	return ""
}
