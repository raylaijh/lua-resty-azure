testing
# Lua Resty Azure

Lua library (based on the resty framework) for Azure authentication and tools. Much of the code is written with the [Azure SDK for Python](https://github.com/Azure/azure-sdk-for-python) as its reference, which in turn uses Autorest to produce the API clients.

There is not yet a Lua client for Autorest, so the clients in this package are ported by-hand.

## Supported Services

The currently supported Azure services are:

* Key Vault (Secrets)

## Supported Authentication Methods

The library currently implements these authentication methods:

* Azure Active Directory Client Credentials (via App Registration)
* Instance Managed Identity Token

## Usage

First of all, we need to instantiate a client. How this is done, depends on the authentication method required.

### Managed Identity Authentication

If using an Instance or Function App with managed identity, you should only need to instantiate a client:

```lua
local azure_client = require("resty.azure"):new()
```

### Client Credentials with Environment Variables

If not using a Managed Identity, you could either set up your environment with the correct credentials:

```sh
export AZURE_TENANT_ID=tenant-uuid
export AZURE_CLIENT_ID=app-registration-client-id
export AZURE_CLIENT_SECRET=app-registration-client-secret
```

then spawn the client:

```lua
local azure_client = require("resty.azure"):new()
```

### Client Credentials with Arguments

Alternatively, if the environment variables are not available, you could pass the configuration required directly to the client constructor in a table:

```lua
local azure_client = require("resty.azure"):new({
  tenant_id = "tenant-uuid",
  client_id = "app-registration-client-id",
  client_secret = "app-registration-client-secret",
})
```

### Using a Service Client

We now have an Azure Client. Authentication, and the exchange of credentials, will not happen until a call is made from a client.

In this example, we get a Key Vault client and use it to get a secret (latest version):

```lua
-- either pass the keyvault URI directly, or call with no arguments and it will be read from the AZURE_DEFAULTS_KEYVAULT_URI environment variable
keyvault_client = azure_client:keyvault("https://keyvault-name.vault.azure.net/")

-- get the secret and check for errors
secret, err = keyvault_client:get_secret("secret-name")
if err then
  ngx.log(ngx.ERR, "Error getting Key Vault secret: ", err)
end
```

## Developing

To contribute to this SDK, just open a Pull Request.

The test framework uses [Kong's Pongo](https://github.com/Kong/kong-pongo) which must be installed first. Included in the fixtures for the tests, is a mock Azure server written in Golang. It will be compiled using the connected container daemon automatically.

To execute the test suite, start and/or connect to your container runtime and then execute the make goal:

```sh
make test
```

## Performing a Release

Creating a release requires a connection to a Docker daemon on the local host.

Execute these commands to create a release in GitHub **AND** Luarocks:

```sh
export LUAROCKS_TOKEN=token-here

# RELEASE_TYPE arg options are "major", "minor", or "patch"
make release RELEASE_TYPE=major

git push --tags origin main
```
