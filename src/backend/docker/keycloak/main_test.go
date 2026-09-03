package main

import (
	"encoding/json"
	"os"
	"path/filepath"
	"testing"
)

func TestLoadRealmTemplatePrefersEnvironmentValue(t *testing.T) {
	templatePath := filepath.Join(t.TempDir(), "realm.json")
	if err := os.WriteFile(templatePath, []byte(`{"realm":"bundled"}`), 0o600); err != nil {
		t.Fatal(err)
	}

	realm, err := loadRealmTemplate(templatePath, `{"realm":"managed"}`)
	if err != nil {
		t.Fatal(err)
	}
	if string(realm) != `{"realm":"managed"}` {
		t.Fatalf("expected managed realm JSON, got %s", realm)
	}
}

func TestLoadRealmTemplateFallsBackToFile(t *testing.T) {
	templatePath := filepath.Join(t.TempDir(), "realm.json")
	if err := os.WriteFile(templatePath, []byte(`{"realm":"bundled"}`), 0o600); err != nil {
		t.Fatal(err)
	}

	realm, err := loadRealmTemplate(templatePath, "")
	if err != nil {
		t.Fatal(err)
	}
	if string(realm) != `{"realm":"bundled"}` {
		t.Fatalf("expected bundled realm JSON, got %s", realm)
	}
}

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
