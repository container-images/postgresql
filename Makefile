.PHONY: build test

TAG="container-images/postgres"

build:
	docker build --tag=$(TAG) .

test: build
	IMAGE_NAME=$(TAG) pytest-3 -vv ./test/*
