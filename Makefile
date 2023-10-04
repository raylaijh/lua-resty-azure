KONG_VERSION:=3.1.1
ARCH:=linux/amd64

.PHONY: test
test:
	@KONG_VERSION=$(KONG_VERSION) pongo run
	KONG_VERSION=$(KONG_VERSION) pongo down


build:
	@docker build --platform=$(ARCH) --build-arg KONG_VERSION=$(KONG_VERSION) -f Dockerfile.release -t kong/lua-resty-azure:release .

.PHONY: release
release: build
	@docker run -it --rm -v $(shell pwd):/host --workdir /host -e LUAROCKS_TOKEN=${LUAROCKS_TOKEN} -e RELEASE_TYPE=$(RELEASE_TYPE) --platform=$(ARCH) kong/lua-resty-azure:release /host/.ci/release.sh

.PHONY: test-release
test-release: build
	@docker run -it --rm -v $(shell pwd):/host --workdir /host -e LUAROCKS_TOKEN=${LUAROCKS_TOKEN} -e RELEASE_TYPE=$(RELEASE_TYPE) --platform=$(ARCH) kong/lua-resty-azure:release /host/.ci/test-release.sh
