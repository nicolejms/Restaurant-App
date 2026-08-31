extension radius

param environment string

@secure()
param authClientSecret string

@secure()
param catalogDatabasePassword string

@secure()
param identityDatabasePassword string

@secure()
param nextAuthSecret string

@secure()
param orderDatabasePassword string

resource restaurantApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'restaurant-app'
  properties: {
    environment: environment
  }
}

resource catalogPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'catalog-postgres'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/catalog-api/src/db/db.rs#L11'
    database: 'catalogdb'
    username: 'catalogadmin'
    password: catalogDatabasePassword
  }
}

resource identityPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'identity-postgres'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'manifests/services/identity-api/base/config.env#L2'
    database: 'identitydb'
    username: 'identityadmin'
    password: identityDatabasePassword
  }
}

resource orderPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'order-postgres'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/order-api/src/main/resources/application.properties#L40'
    database: 'orderdb'
    username: 'orderadmin'
    password: orderDatabasePassword
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'redis'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/cart-api/cmd/api/main.go#L222'
    size: 'S'
  }
}

resource kafkaBroker 'Radius.Messaging/kafka@2025-08-01-preview' = {
  name: 'kafka'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/checkout-api/src/messagging/publisher.ts#L33'
    topic: 'checkout'
  }
}

resource otelCollectorConfig 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'otel-collector-config'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    data: {
      'otel-collector-config.yaml': {
        #disable-next-line use-secure-value-for-secure-inputs
        value: '''
receivers:
  otlp:
    protocols:
      grpc:
        endpoint: 0.0.0.0:4317
      http:
        endpoint: 0.0.0.0:4318
exporters:
  logging:
    loglevel: info
processors:
  batch:
service:
  pipelines:
    traces:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
    metrics:
      receivers: [otlp]
      processors: [batch]
      exporters: [logging]
'''
      }
    }
  }
}

resource cartImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'cart-api-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/cart-api/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/cart-api?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource catalogImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'catalog-api-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/catalog-api/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/catalog-api?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource checkoutImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'checkout-api-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/checkout-api/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/checkout-api?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource orderImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'order-api-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/order-api/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/order-api?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource paymentImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'payment-api-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/payment-api/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/payment-api?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource webImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'web-app-image'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/web-app/Dockerfile'
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/web-app?ref=7f3e81842b82d9064a282ad4ad1bde7d0e2c35a4'
      platforms: [
        'linux/amd64'
      ]
    }
  }
}

resource otelCollectorContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'otel-collector'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      collector: {
        image: 'otel/opentelemetry-collector-contrib:0.85.0'
        args: [
          '--config=/etc/otel-collector/otel-collector-config.yaml'
        ]
        ports: {
          grpc: {
            containerPort: 4317
          }
          http: {
            containerPort: 4318
          }
        }
        volumeMounts: [
          {
            volumeName: 'config'
            mountPath: '/etc/otel-collector'
          }
        ]
      }
    }
    volumes: {
      config: {
        secretName: otelCollectorConfig.name
      }
    }
  }
}

resource cartContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'cart-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/cart-api/cmd/api/main.go#L61'
    containers: {
      cart: {
        image: cartImage.properties.imageReference
        env: {
          BASE_PATH: {
            value: '/shoppingcart'
          }
          KAFKA_BROKER: {
            value: '${kafkaBroker.properties.host}:9092'
          }
          ORDERS_TOPIC: {
            value: 'orders'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT: {
            value: '${otelCollectorContainer.properties.hosts['collector']}:4317'
          }
          REDIS_HOST: {
            value: '${redisCache.properties.host}:${redisCache.properties.port}'
          }
        }
        ports: {
          grpc: {
            containerPort: 8081
          }
          web: {
            containerPort: 5200
          }
        }
      }
    }
    connections: {
      kafka: {
        source: kafkaBroker.id
      }
      rediscache: {
        source: redisCache.id
      }
    }
  }
}

resource catalogContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'catalog-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/catalog-api/src/main.rs#L70'
    containers: {
      catalog: {
        image: catalogImage.properties.imageReference
        command: [
          '/bin/sh'
          '-c'
        ]
        args: [
          'export DATABASE_URL="postgres://catalogadmin:$1@$2:5432/catalogdb"; exec ./catalog-api'
          'catalog-api'
          catalogDatabasePassword
          catalogPostgresDb.properties.host
        ]
        env: {
          BASE_URL: {
            value: '/catalog'
          }
          ENV: {
            value: 'production'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT: {
            value: 'http://${otelCollectorContainer.properties.hosts['collector']}:4317'
          }
          ROCKET_ADDRESS: {
            value: '0.0.0.0'
          }
          ROCKET_PORT: {
            value: '8000'
          }
        }
        ports: {
          web: {
            containerPort: 8000
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: catalogPostgresDb.id
      }
    }
  }
}

resource checkoutContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'checkout-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/checkout-api/src/index.ts#L30'
    containers: {
      checkout: {
        image: checkoutImage.properties.imageReference
        env: {
          BASE_URL: {
            value: '/checkout'
          }
          CART_URL: {
            value: '${cartContainer.properties.hosts['cart']}:8081'
          }
          CHECKOUT_TOPIC: {
            value: 'checkout'
          }
          HOST: {
            value: '0.0.0.0'
          }
          KAFKA_BROKER: {
            value: '${kafkaBroker.properties.host}:9092'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT: {
            value: 'http://${otelCollectorContainer.properties.hosts['collector']}:4317'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT_HTTP: {
            value: 'http://${otelCollectorContainer.properties.hosts['collector']}:4318/v1/metrics'
          }
          PAYMENT_API_URL: {
            value: '${paymentContainer.properties.hosts['payment']}:8080'
          }
          PORT: {
            value: '30001'
          }
        }
        ports: {
          web: {
            containerPort: 30001
          }
        }
      }
    }
    connections: {
      kafka: {
        source: kafkaBroker.id
      }
    }
  }
}

resource identityContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'identity-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      identity: {
        image: 'ghcr.io/chayxana/identity-api:0.0.8'
        env: {
          ASPNETCORE_ENVIRONMENT: {
            value: 'Development'
          }
          DB_HOST: {
            value: identityPostgresDb.properties.host
          }
          DB_NAME: {
            value: 'identitydb'
          }
          DB_PASSWORD: {
            value: identityDatabasePassword
          }
          DB_USER: {
            value: 'identityadmin'
          }
          PATH_BASE: {
            value: '/identity'
          }
        }
        ports: {
          web: {
            containerPort: 80
          }
        }
      }
    }
    connections: {
      postgresdb: {
        source: identityPostgresDb.id
      }
    }
  }
}

resource orderContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'order-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      order: {
        image: orderImage.properties.imageReference
        env: {
          KAFKA_BOOTSTRAP_SERVERS: {
            value: '${kafkaBroker.properties.host}:9092'
          }
          QUARKUS_DATASOURCE_JDBC_URL: {
            value: 'jdbc:postgresql://${orderPostgresDb.properties.host}:5432/orderdb'
          }
          QUARKUS_DATASOURCE_PASSWORD: {
            value: orderDatabasePassword
          }
          QUARKUS_DATASOURCE_USERNAME: {
            value: 'orderadmin'
          }
          QUARKUS_GRPC_CLIENTS_PAYMENTSERVICE_HOST: {
            value: paymentContainer.properties.hosts['payment']
          }
          QUARKUS_GRPC_CLIENTS_PAYMENTSERVICE_PORT: {
            value: '8080'
          }
          QUARKUS_OPENTELEMETRY_TRACER_EXPORTER_OTLP_ENDPOINT: {
            value: 'http://${otelCollectorContainer.properties.hosts['collector']}:4317'
          }
          QUARKUS_PROFILE: {
            value: 'prod'
          }
        }
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
    connections: {
      kafka: {
        source: kafkaBroker.id
      }
      postgresdb: {
        source: orderPostgresDb.id
      }
    }
  }
}

resource paymentContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'payment-api'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'src/backend/services/payment-api/main.go#L22'
    containers: {
      payment: {
        image: paymentImage.properties.imageReference
        env: {
          BASE_PATH: {
            value: '/payment'
          }
          ENABLE_TEST_CARDS: {
            value: 'true'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT: {
            value: '${otelCollectorContainer.properties.hosts['collector']}:4317'
          }
        }
        ports: {
          grpc: {
            containerPort: 8080
          }
          http: {
            containerPort: 8980
          }
        }
      }
    }
  }
}

resource webContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web-app'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      web: {
        image: webImage.properties.imageReference
        env: {
          AUTH_CLIENT_ID: {
            value: 'nextjs-web-app'
          }
          AUTH_CLIENT_SECRET: {
            value: authClientSecret
          }
          AUTH_ISSUER: {
            value: 'http://gateway-istio.istio-system/identity'
          }
          AUTH_INTERNAL_ISSUER: {
            value: 'http://${identityContainer.properties.hosts['identity']}/identity'
          }
          INTERNAL_API_BASE_URL: {
            value: 'http://gateway-istio.istio-system'
          }
          NEXTAUTH_SECRET: {
            value: nextAuthSecret
          }
          NEXTAUTH_URL: {
            value: 'http://localhost:3001'
          }
          OTEL_EXPORTER_OTLP_ENDPOINT: {
            value: 'http://${otelCollectorContainer.properties.hosts['collector']}:4318'
          }
        }
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
  }
}

resource appRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'restaurant-app-route'
  properties: {
    environment: environment
    application: restaurantApp.id
    codeReference: 'manifests/infrastructure/gateway/gateway.yaml#L1'
    kind: 'HTTP'
    rules: [
      {
        matches: [
          {
            httpPath: '/'
          }
        ]
        destinationContainer: {
          resourceId: webContainer.id
          containerName: 'web'
          containerPort: 3000
        }
      }
      {
        matches: [
          {
            httpPath: '/catalog'
          }
        ]
        destinationContainer: {
          resourceId: catalogContainer.id
          containerName: 'catalog'
          containerPort: 8000
        }
      }
      {
        matches: [
          {
            httpPath: '/checkout'
          }
        ]
        destinationContainer: {
          resourceId: checkoutContainer.id
          containerName: 'checkout'
          containerPort: 30001
        }
      }
      {
        matches: [
          {
            httpPath: '/identity'
          }
        ]
        destinationContainer: {
          resourceId: identityContainer.id
          containerName: 'identity'
          containerPort: 80
        }
      }
      {
        matches: [
          {
            httpPath: '/order'
          }
        ]
        destinationContainer: {
          resourceId: orderContainer.id
          containerName: 'order'
          containerPort: 8080
        }
      }
      {
        matches: [
          {
            httpPath: '/shoppingcart'
          }
        ]
        destinationContainer: {
          resourceId: cartContainer.id
          containerName: 'cart'
          containerPort: 5200
        }
      }
    ]
  }
}
