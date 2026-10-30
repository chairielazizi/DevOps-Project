IP := $(shell curl -fsS https://ifconfig.me 2>/dev/null)

.PHONY: all
all:
    @echo "Detected server public IP: $(IP)"
    sed -i "s/__SERVER_IP__/$(IP)/g" prometheus/prometheus.yaml prometheus/targets.json
    @echo "Placeholders updated."

