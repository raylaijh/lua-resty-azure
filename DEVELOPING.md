# lua-resty-azure Development and Contribution Guide

## Adding a new SDK Implementation

Each API/SDK implementation and endpoint capability is added manually into this library, due to its emphasis on performance and memory management.

To implement a new interface, you must create the new service module under `resty/azure/api` ensuring that it implements at least the `:new` method that also receives and stores the parent_client:

```lua
local new_svc_implementation = {}
new_svc_implementation.__index = new_svc_implementation

function new_svc_implementation:new(parent_client, custom_arg_1, custom_arg_2)
  local self = {}  -- override 'self' to be the new object/class
  setmetatable(self, new_svc_implementation)
  
  self.parent_client = parent_client
  
  -- do any further initialisation with the "custom args" here

  return self
end
```

Finally, you must also add it to the `rockspec` under the `modules` section. It should immediately be available for the calling client to use, and discovered automatically at Resty VM startup time.

## Releases

When a release is ready in the main branch, make sure the working head is clean, then run the make target with the right environment setup:

```sh
git config user.name "Developer Name in GitHub"
git config user.email "Developer-Email-Address-in-GitHub@domain.local"
git config user.signingkey pgp-key-long-format-id   # optional PGP signing key

export LUAROCKS_TOKEN=<token>
make release RELEASE_TYPE=[major/minor/patch]
```

Afterwards, **please remember to push the working head to origin:**

```sh
git push --tags origin main
```
