# CI configuration

The blocking backend job builds, runs the full race/coverage suite once, enforces the existing 50-percent threshold, and runs vet and lint. The independent vulnerability job remains. Frontend tests, browser E2E, database migration tests, private Compose integration, amd64 image scans and arm64 image builds remain separate gates.

Coverage diagnostics come from the blocking suite; the separate report-only coverage rerun is removed. The backend image is built and scanned in the image job, and the architecture job builds arm64 without repeating amd64. Benchmarks remain separate. GitHub SARIF upload and OSSF Scorecard are host-scoped; actual vulnerability scans remain on Gitea.

PostgreSQL containers include run, attempt and job in their names and an ownership label. Containerized jobs share only their own network namespace; host jobs use ephemeral loopback ports. Cleanup refuses containers without the matching ownership label. Compose integration renders a private stack with generated names, private networks and volumes, and no published ports. Smoke requests run inside that network. The retained-data backup service is excluded from disposable integration.

Staging and production deployment files are manual scaffolding failures. They cannot claim deployment, health or rollback success until real operator, source, deployment and recovery contracts are implemented. No deployment was performed while preparing this change.
