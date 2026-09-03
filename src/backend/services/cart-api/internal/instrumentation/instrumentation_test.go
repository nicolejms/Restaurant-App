package instrumentation

import (
	"context"
	"testing"
)

func TestStartOTELWithoutEndpoint(t *testing.T) {
	t.Setenv("OTEL_EXPORTER_OTLP_ENDPOINT", "")

	close, err := StartOTEL(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	close()
}
