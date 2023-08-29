.PHONY: docker podman

docker:
	@docker build -t aeternity/aerepl-web:local .

podman:
	@podman build --format docker -t aeternity/aerepl-web:local .
