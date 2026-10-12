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
    for section in ("networks", "volumes"):
        for value in config.get(section, {}).values():
            value.pop("name", None)
            value.pop("external", None)
    return config


if __name__ == "__main__":
    json.dump(isolate(json.load(sys.stdin)), sys.stdout, indent=2)
    sys.stdout.write("\n")
