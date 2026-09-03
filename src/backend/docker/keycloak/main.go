package main

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
)

const (
	defaultClientID     = "nextjs-web-app"
	defaultOutputPath   = "/import/realm.json"
	defaultTemplatePath = "/template/realm.json"
)

func main() {
	clientSecret := os.Getenv("AUTH_CLIENT_SECRET")
	if clientSecret == "" {
		exitWithError(fmt.Errorf("AUTH_CLIENT_SECRET is required"))
	}

	templatePath := environmentOrDefault("REALM_TEMPLATE_PATH", defaultTemplatePath)
	outputPath := environmentOrDefault("REALM_OUTPUT_PATH", defaultOutputPath)
	clientID := environmentOrDefault("AUTH_CLIENT_ID", defaultClientID)

	realmJSON, err := os.ReadFile(templatePath)
	if err != nil {
		exitWithError(fmt.Errorf("read realm template: %w", err))
	}

	updatedRealm, err := injectClientSecret(realmJSON, clientID, clientSecret)
	if err != nil {
		exitWithError(err)
	}
	if err := os.MkdirAll(filepath.Dir(outputPath), 0o750); err != nil {
		exitWithError(fmt.Errorf("create realm output directory: %w", err))
	}
	if err := os.WriteFile(outputPath, updatedRealm, 0o600); err != nil {
		exitWithError(fmt.Errorf("write rendered realm: %w", err))
	}
}

func injectClientSecret(realmJSON []byte, clientID, clientSecret string) ([]byte, error) {
	var realm map[string]any
	if err := json.Unmarshal(realmJSON, &realm); err != nil {
		return nil, fmt.Errorf("parse realm template: %w", err)
	}

	clients, ok := realm["clients"].([]any)
	if !ok {
		return nil, fmt.Errorf("realm template has no clients array")
	}
	for _, rawClient := range clients {
		client, ok := rawClient.(map[string]any)
		if ok && client["clientId"] == clientID {
			client["secret"] = clientSecret
			renderedRealm, err := json.MarshalIndent(realm, "", "  ")
			if err != nil {
				return nil, fmt.Errorf("render realm template: %w", err)
			}
			return append(renderedRealm, '\n'), nil
		}
	}

	return nil, fmt.Errorf("realm template has no client %q", clientID)
}

func environmentOrDefault(name, fallback string) string {
	if value := os.Getenv(name); value != "" {
		return value
	}
	return fallback
}

func exitWithError(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
