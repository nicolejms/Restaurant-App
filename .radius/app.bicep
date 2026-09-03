extension radius

@secure()
param authClientSecret string

@secure()
param catalogDatabasePassword string

param environment string

@secure()
param identityDatabasePassword string

@secure()
param keycloakAdminPassword string

@secure()
param keycloakRealmJson string

@secure()
param nextAuthSecret string

@secure()
param orderDatabasePassword string

param publicHostname string

@allowed([
  'http'
  'https'
])
param publicScheme string = 'https'

@secure()
param registryPassword string

param registryUsername string

resource restaurantApp 'Radius.Core/applications@2025-08-01-preview' = {
  name: 'restaurant-app'
  properties: {
    environment: environment
  }
}

resource catalogPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'catalog-postgres'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/catalog-api/src/db/db.rs#L8'
    database: 'catalogdb'
    environment: environment
    password: catalogDatabasePassword
    port: 5432
    size: 'S'
    username: 'catalogadmin'
  }
}

resource identityPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'identity-postgres'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/docker/docker-compose.override.yml#L61'
    database: 'keycloak'
    environment: environment
    password: identityDatabasePassword
    port: 5432
    size: 'S'
    username: 'identityadmin'
  }
}

resource orderPostgresDb 'Radius.Data/postgreSqlDatabases@2025-08-01-preview' = {
  name: 'order-postgres'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/order-api/src/main/resources/application.properties#L30'
    database: 'orderdb'
    environment: environment
    password: orderDatabasePassword
    port: 5432
    size: 'S'
    username: 'orderadmin'
  }
}

resource redisCache 'Radius.Data/redisCaches@2025-08-01-preview' = {
  name: 'redis'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/cart-api/cmd/config/managed_connections.go#L17'
    environment: environment
    size: 'S'
  }
}

resource checkoutKafka 'Radius.Messaging/kafka@2025-08-01-preview' = {
  name: 'checkout-kafka'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/checkout-api/src/messagging/publisher.ts#L34'
    environment: environment
    topic: 'checkout'
  }
}

resource ordersKafka 'Radius.Messaging/kafka@2025-08-01-preview' = {
  name: 'orders-kafka'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/order-api/src/main/resources/application.properties#L19'
    environment: environment
    topic: 'orders'
  }
}

resource appSecrets 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'app-secrets'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/web-app/src/lib/auth.ts#L16'
    data: {
      authClientSecret: {
        value: authClientSecret
      }
      catalogDatabasePassword: {
        value: catalogDatabasePassword
      }
      identityDatabasePassword: {
        value: identityDatabasePassword
      }
      keycloakAdminPassword: {
        value: keycloakAdminPassword
      }
      keycloakRealmJson: {
        value: keycloakRealmJson
      }
      nextAuthSecret: {
        value: nextAuthSecret
      }
      orderDatabasePassword: {
        value: orderDatabasePassword
      }
    }
    environment: environment
    kind: 'generic'
  }
}

resource registryCreds 'Radius.Security/secrets@2025-08-01-preview' = {
  name: 'radius-ghcr-registry-creds'
  properties: {
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    data: {
      password: {
        value: registryPassword
      }
      username: {
        #disable-next-line use-secure-value-for-secure-inputs
        value: registryUsername
      }
    }
    environment: environment
    kind: 'basicAuthentication'
  }
}

resource cartImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'cart-api-image'
  properties: {
    application: restaurantApp.id
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/cart-api?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/cart-api/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource catalogImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'catalog-api-image'
  properties: {
    application: restaurantApp.id
    build: {
      platforms: [
        'linux/amd64'
      ]
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/catalog-api?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/catalog-api/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource checkoutImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'checkout-api-image'
  properties: {
    application: restaurantApp.id
    build: {
      platforms: [
        'linux/amd64'
      ]
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/checkout-api?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/checkout-api/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource keycloakRealmInitImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'keycloak-realm-init-image'
  properties: {
    application: restaurantApp.id
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/docker/keycloak?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/docker/keycloak/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource orderImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'order-api-image'
  properties: {
    application: restaurantApp.id
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/order-api?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/order-api/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource paymentImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'payment-api-image'
  properties: {
    application: restaurantApp.id
    build: {
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/payment-api?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/payment-api/Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource webImage 'Radius.Compute/containerImages@2025-08-01-preview' = {
  name: 'web-app-image'
  properties: {
    application: restaurantApp.id
    build: {
      dockerfile: 'local.Dockerfile'
      platforms: [
        'linux/amd64'
      ]
      source: 'git::https://github.com/nicolejms/Restaurant-App.git//src/backend/services/web-app?ref=ba20e090713f80cff16546dc59f2776ff6830c33'
    }
    codeReference: 'src/backend/services/web-app/local.Dockerfile#L1'
    environment: environment
  }
  dependsOn: [
    registryCreds
  ]
}

resource cartContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'cart-api'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/cart-api/cmd/api/main.go#L61'
    connections: {
      ordersKafka: {
        disableDefaultEnvVars: true
        source: ordersKafka.id
      }
      redis: {
        disableDefaultEnvVars: true
        source: redisCache.id
      }
    }
    containers: {
      cart: {
        env: {
          AUTH_URL: {
            value: '${publicScheme}://${toLower(publicHostname)}/identity/realms/restaurant'
          }
          BASE_PATH: {
            value: '/shoppingcart'
          }
          CONNECTION_ORDERSKAFKA_CONNECTIONSTRING: {
            valueFrom: {
              secretKeyRef: {
                key: 'connectionString'
                secretName: ordersKafka.properties.secrets.name
              }
            }
          }
          CONNECTION_REDIS_URL: {
            valueFrom: {
              secretKeyRef: {
                key: 'url'
                secretName: redisCache.properties.secrets.name
              }
            }
          }
          IDENTITY_URL: {
            value: 'http://${keycloakContainer.properties.hosts.keycloak}:8080/identity'
          }
          ORDERS_TOPIC: {
            value: 'orders'
          }
        }
        image: cartImage.properties.imageReference
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
    environment: environment
    restartPolicy: 'Always'
  }
}

resource catalogContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'catalog-api'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/catalog-api/src/main.rs#L69'
    containers: {
      catalog: {
        env: {
          BASE_URL: {
            value: '/catalog'
          }
          DATABASE_HOST: {
            value: catalogPostgresDb.properties.host
          }
          DATABASE_NAME: {
            value: 'catalogdb'
          }
          DATABASE_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                key: 'catalogDatabasePassword'
                secretName: appSecrets.name
              }
            }
          }
          DATABASE_PORT: {
            value: '${catalogPostgresDb.properties.port}'
          }
          DATABASE_USERNAME: {
            value: 'catalogadmin'
          }
          ENV: {
            value: 'prod'
          }
          ROCKET_ADDRESS: {
            value: '0.0.0.0'
          }
          ROCKET_PORT: {
            value: '8000'
          }
        }
        image: catalogImage.properties.imageReference
        ports: {
          web: {
            containerPort: 8000
          }
        }
      }
    }
    environment: environment
    restartPolicy: 'Always'
  }
}

resource checkoutContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'checkout-api'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/checkout-api/src/index.ts#L30'
    connections: {
      checkoutKafka: {
        disableDefaultEnvVars: true
        source: checkoutKafka.id
      }
    }
    containers: {
      checkout: {
        env: {
          BASE_URL: {
            value: '/checkout'
          }
          CART_URL: {
            value: '${cartContainer.properties.hosts.cart}:8081'
          }
          CHECKOUT_TOPIC: {
            value: 'checkout'
          }
          CONNECTION_CHECKOUTKAFKA_CONNECTIONSTRING: {
            valueFrom: {
              secretKeyRef: {
                key: 'connectionString'
                secretName: checkoutKafka.properties.secrets.name
              }
            }
          }
          HOST: {
            value: '0.0.0.0'
          }
          LOG_LEVEL: {
            value: 'debug'
          }
          PAYMENT_API_URL: {
            value: '${paymentContainer.properties.hosts.payment}:8080'
          }
          PORT: {
            value: '30001'
          }
        }
        image: checkoutImage.properties.imageReference
        ports: {
          web: {
            containerPort: 30001
          }
        }
      }
    }
    environment: environment
    restartPolicy: 'Always'
  }
}

resource keycloakContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'keycloak'
  properties: {
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      keycloak: {
        args: [
          'start-dev'
          '--import-realm'
        ]
        env: {
          KC_DB: {
            value: 'postgres'
          }
          KC_DB_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                key: 'identityDatabasePassword'
                secretName: appSecrets.name
              }
            }
          }
          KC_DB_URL: {
            value: 'jdbc:postgresql://${identityPostgresDb.properties.host}:${identityPostgresDb.properties.port}/keycloak'
          }
          KC_DB_USERNAME: {
            value: 'identityadmin'
          }
          KC_HOSTNAME: {
            value: '${publicScheme}://${toLower(publicHostname)}/identity'
          }
          KC_HTTP_RELATIVE_PATH: {
            value: '/identity'
          }
          KC_PROXY_HEADERS: {
            value: 'xforwarded'
          }
          KEYCLOAK_ADMIN: {
            value: 'admin'
          }
          KEYCLOAK_ADMIN_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                key: 'keycloakAdminPassword'
                secretName: appSecrets.name
              }
            }
          }
        }
        image: 'quay.io/keycloak/keycloak:26.0'
        ports: {
          web: {
            containerPort: 8080
          }
        }
        volumeMounts: [
          {
            mountPath: '/opt/keycloak/data/import'
            volumeName: 'realmImport'
          }
        ]
      }
      realmInit: {
        env: {
          AUTH_CLIENT_ID: {
            value: 'nextjs-web-app'
          }
          AUTH_CLIENT_SECRET: {
            valueFrom: {
              secretKeyRef: {
                key: 'authClientSecret'
                secretName: appSecrets.name
              }
            }
          }
          KEYCLOAK_REALM_JSON: {
            valueFrom: {
              secretKeyRef: {
                key: 'keycloakRealmJson'
                secretName: appSecrets.name
              }
            }
          }
        }
        image: keycloakRealmInitImage.properties.imageReference
        initContainer: true
        volumeMounts: [
          {
            mountPath: '/import'
            volumeName: 'realmImport'
          }
        ]
      }
    }
    environment: environment
    restartPolicy: 'Always'
    volumes: {
      realmImport: {
        emptyDir: {
          medium: 'disk'
        }
      }
    }
  }
}

resource orderContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'order-api'
  properties: {
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    connections: {
      checkoutKafka: {
        disableDefaultEnvVars: true
        source: checkoutKafka.id
      }
      ordersKafka: {
        disableDefaultEnvVars: true
        source: ordersKafka.id
      }
    }
    containers: {
      order: {
        env: {
          CONNECTION_CHECKOUTKAFKA_CONNECTIONSTRING: {
            valueFrom: {
              secretKeyRef: {
                key: 'connectionString'
                secretName: checkoutKafka.properties.secrets.name
              }
            }
          }
          CONNECTION_ORDERSKAFKA_CONNECTIONSTRING: {
            valueFrom: {
              secretKeyRef: {
                key: 'connectionString'
                secretName: ordersKafka.properties.secrets.name
              }
            }
          }
          QUARKUS_DATASOURCE_JDBC_URL: {
            value: 'jdbc:postgresql://${orderPostgresDb.properties.host}:${orderPostgresDb.properties.port}/orderdb'
          }
          QUARKUS_DATASOURCE_PASSWORD: {
            valueFrom: {
              secretKeyRef: {
                key: 'orderDatabasePassword'
                secretName: appSecrets.name
              }
            }
          }
          QUARKUS_DATASOURCE_USERNAME: {
            value: 'orderadmin'
          }
          QUARKUS_GRPC_CLIENTS_PAYMENTSERVICE_HOST: {
            value: paymentContainer.properties.hosts.payment
          }
          QUARKUS_GRPC_CLIENTS_PAYMENTSERVICE_PORT: {
            value: '8080'
          }
          QUARKUS_LOG_CONSOLE_JSON: {
            value: 'true'
          }
        }
        image: orderImage.properties.imageReference
        ports: {
          web: {
            containerPort: 8080
          }
        }
      }
    }
    environment: environment
    restartPolicy: 'Always'
  }
}

resource paymentContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'payment-api'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/services/payment-api/main.go#L22'
    containers: {
      payment: {
        env: {
          BASE_PATH: {
            value: '/payment'
          }
          ENABLE_TEST_CARDS: {
            value: 'false'
          }
        }
        image: paymentImage.properties.imageReference
        ports: {
          grpc: {
            containerPort: 8080
          }
          web: {
            containerPort: 8980
          }
        }
      }
    }
    environment: environment
    restartPolicy: 'Always'
  }
}

resource webContainer 'Radius.Compute/containers@2025-08-01-preview' = {
  name: 'web-app'
  properties: {
    application: restaurantApp.id
    codeReference: '.radius/app.bicep'
    containers: {
      web: {
        env: {
          AUTH_CLIENT_ID: {
            value: 'nextjs-web-app'
          }
          AUTH_CLIENT_SECRET: {
            valueFrom: {
              secretKeyRef: {
                key: 'authClientSecret'
                secretName: appSecrets.name
              }
            }
          }
          AUTH_INTERNAL_ISSUER: {
            value: 'http://${keycloakContainer.properties.hosts.keycloak}:8080/identity/realms/restaurant'
          }
          AUTH_ISSUER: {
            value: '${publicScheme}://${toLower(publicHostname)}/identity/realms/restaurant'
          }
          CART_API_URL: {
            value: 'http://${cartContainer.properties.hosts.cart}:5200/shoppingcart'
          }
          CATALOG_API_URL: {
            value: 'http://${catalogContainer.properties.hosts.catalog}:8000/catalog'
          }
          CHECKOUT_API_URL: {
            value: 'http://${checkoutContainer.properties.hosts.checkout}:30001/checkout'
          }
          NEXTAUTH_SECRET: {
            valueFrom: {
              secretKeyRef: {
                key: 'nextAuthSecret'
                secretName: appSecrets.name
              }
            }
          }
          NEXTAUTH_URL: {
            value: '${publicScheme}://${toLower(publicHostname)}'
          }
          NEXT_SHARP_PATH: {
            value: './node_modules/sharp'
          }
          ORDER_API_URL: {
            value: 'http://${orderContainer.properties.hosts.order}:8080/order'
          }
          PUBLIC_API_BASE_URL: {
            value: '${publicScheme}://${toLower(publicHostname)}'
          }
        }
        image: webImage.properties.imageReference
        ports: {
          web: {
            containerPort: 3000
          }
        }
      }
    }
    environment: environment
    restartPolicy: 'Always'
  }
}

resource restaurantRoute 'Radius.Compute/routes@2025-08-01-preview' = {
  name: 'restaurant-app'
  properties: {
    application: restaurantApp.id
    codeReference: 'src/backend/docker/docker-compose.traefik.yml#L27'
    environment: environment
    hostnames: [
      toLower(publicHostname)
    ]
    kind: 'HTTP'
    rules: [
      {
        destinationContainer: {
          containerName: 'keycloak'
          containerPort: 8080
          resourceId: keycloakContainer.id
        }
        matches: [
          {
            httpPath: '/identity'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'payment'
          containerPort: 8980
          resourceId: paymentContainer.id
        }
        matches: [
          {
            httpPath: '/payment'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'catalog'
          containerPort: 8000
          resourceId: catalogContainer.id
        }
        matches: [
          {
            httpPath: '/catalog'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'cart'
          containerPort: 5200
          resourceId: cartContainer.id
        }
        matches: [
          {
            httpPath: '/shoppingcart'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'order'
          containerPort: 8080
          resourceId: orderContainer.id
        }
        matches: [
          {
            httpPath: '/order'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'checkout'
          containerPort: 30001
          resourceId: checkoutContainer.id
        }
        matches: [
          {
            httpPath: '/checkout'
          }
        ]
      }
      {
        destinationContainer: {
          containerName: 'web'
          containerPort: 3000
          resourceId: webContainer.id
        }
        matches: [
          {
            httpPath: '/'
          }
        ]
      }
    ]
  }
}
