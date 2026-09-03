package main

import (
	"encoding/json"
	"testing"
)

func TestInjectClientSecret(t *testing.T) {
	template := []byte(`{"realm":"restaurant","clients":[{"clientId":"nextjs-web-app","secret":"development"}]}`)

	rendered, err := injectClientSecret(template, "nextjs-web-app", "managed-secret")
	if err != nil {
		t.Fatal(err)
	}

	var realm map[string]any
	if err := json.Unmarshal(rendered, &realm); err != nil {
		t.Fatal(err)
	}
	client := realm["clients"].([]any)[0].(map[string]any)
	if client["secret"] != "managed-secret" {
		t.Fatalf("expected injected secret, got %v", client["secret"])
	}
}

func TestInjectClientSecretRejectsMissingClient(t *testing.T) {
	template := []byte(`{"realm":"restaurant","clients":[]}`)

	if _, err := injectClientSecret(template, "nextjs-web-app", "managed-secret"); err == nil {
		t.Fatal("expected missing client error")
	}
}
