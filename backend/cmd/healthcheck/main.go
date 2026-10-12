package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"time"
)

func main() {
	// Default to /healthz for consistency with Kubernetes manifests.
	// Override with HEALTHCHECK_ENDPOINT=http://localhost:8080/readyz for stricter checks
	// (DB connectivity, circuit breaker state, credentials presence).
	endpoint := os.Getenv("HEALTHCHECK_ENDPOINT")
	if endpoint == "" {
		endpoint = "http://localhost:8080/healthz"
	}

	client := &http.Client{Timeout: 3 * time.Second}
	ctx := context.Background()
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil) // #nosec G704 -- Endpoint is operator-owned environment configuration, not request input.
	if err != nil {
		os.Exit(1)
	}
	resp, err := client.Do(req) // #nosec G704 -- Operator-configured health checks intentionally support private service addresses.
	if err != nil {
		os.Exit(1)
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.Printf("failed to close response body: %v", err)
		}
	}()
	if resp.StatusCode != 200 {
		os.Exit(1)
	}
}
