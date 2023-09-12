local build_request = require("resty.azure.api.request.build")

describe("build_request", function()
  it("should build a request object with method and token", function()
    local method = "GET"
    local token = "my-token"
    local request, err = build_request(method, nil, token)

    assert.is_nil(err)
    assert.is_table(request)
    assert.is_equal(request.method, method)
    assert.is_table(request.headers)
    assert.is_equal(request.headers["Authorization"], "Bearer " .. token)
    assert.is_true(request.ssl_verify)
  end)

  it("should build a request object with method, body, and token", function()
    local method = "POST"
    local token = "my-token"
    local body = { foo = "bar" }
    local request, err = build_request(method, body, token)

    assert.is_nil(err)
    assert.is_table(request)
    assert.is_equal(request.method, method)
    assert.is_table(request.headers)
    assert.is_equal(request.headers["Authorization"], "Bearer " .. token)
    assert.is_true(request.ssl_verify)
    assert.is_equal(request.body, '{"foo":"bar"}')
    assert.is_equal(request.headers["Content-Type"], "application/json; charset=utf-8")
  end)

  it("should return an error if no method is defined", function()
    assert.error(function () build_request(nil, nil, "my-token") end, "no method defined")
  end)

  it("should return an error if no token is defined", function()
    assert.error(function () build_request("GET", nil, nil) end, "no token defined")
  end)

  it("should build a request object with method, body, token, and ssl", function()
    local method = "POST"
    local token = "my-token"
    local body = { foo = "bar" }
    local ssl = true
    local request, err = build_request(method, body, token, ssl)

    assert.is_nil(err)
    assert.is_table(request)
    assert.is_equal(request.method, method)
    assert.is_table(request.headers)
    assert.is_equal(request.headers["Authorization"], "Bearer " .. token)
    assert.is_equal(request.ssl_verify, ssl)
    assert.is_equal(request.body, '{"foo":"bar"}')
    assert.is_equal(request.headers["Content-Type"], "application/json; charset=utf-8")
  end)

  it("should build a request object with method, body, token, and no ssl", function()
    local method = "POST"
    local token = "my-token"
    local body = { foo = "bar" }
    local ssl = false
    local request, err = build_request(method, body, token, ssl)

    assert.is_nil(err)
    assert.is_table(request)
    assert.is_equal(request.method, method)
    assert.is_table(request.headers)
    assert.is_equal(request.headers["Authorization"], "Bearer " .. token)
    assert.is_equal(request.ssl_verify, ssl)
    assert.is_equal(request.body, '{"foo":"bar"}')
    assert.is_equal(request.headers["Content-Type"], "application/json; charset=utf-8")
  end)
end)
