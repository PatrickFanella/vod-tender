"""Convert rendered development Compose into a private disposable CI stack."""
import json
import sys


def isolate(config):
    config.pop("name", None)
    # Backup is a retained-data operation, not an integration-test dependency.
    config["services"].pop("backup", None)
    for service in config["services"].values():
        service.pop("container_name", None)
        service.pop("ports", None)
        service.pop("restart", None)
    # Fresh databases can spend time in initdb on a loaded runner. Readiness
    # must use the final TCP listener, not initdb's temporary Unix socket.
    postgres = config["services"]["postgres"]
    postgres["healthcheck"] = {
        "test": ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U $$POSTGRES_USER -d $$POSTGRES_DB"],
        "start_period": "60s",
        "interval": "5s",
        "timeout": "5s",
        "retries": 12,
    }
    for section in ("networks", "volumes"):
        for value in config.get(section, {}).values():
            value.pop("name", None)
            value.pop("external", None)
    return config


if __name__ == "__main__":
    json.dump(isolate(json.load(sys.stdin)), sys.stdout, indent=2)
    sys.stdout.write("\n")
