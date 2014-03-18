
import load_test_server, close_test_server, request
  from require "lapis.spec.server"

should_load = (url, expected_status=200) ->
  it "should load #{url} with #{expected_status}", ->
    assert.same expected_status, (request url)

import truncate_tables from require "lapis.spec.db"

import log_in_user from require "spec.helpers"

import generate_token from require "lapis.csrf"

import
  Manifests
  Users
  Modules
  Versions
  Rocks
  from require "models"

rockspec = [==[
-- etlua-dev-1.rockspec
package = "etlua"
version = "dev-1"

source = {
  url = "git://github.com/leafo/etlua.git"
}

description = {
  summary = "Embedded templates for Lua",
  detailed = [[
    Allows you to render ERB style templates but with Lua. Supports <% %>, <%=
    %> and <%- %> tags (with optional newline slurping) for embedding code.
  ]],
  homepage = "https://github.com/leafo/etlua",
  maintainer = "Leaf Corcoran <leafot@gmail.com>",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1",
}

build = {
  type = "builtin",
  modules = {
    ["etlua"] = "etlua.lua",
  },
}

]==]

describe "moonrocks", ->
  setup ->
    load_test_server!

    truncate_tables Manifests
    Manifests\create "root", true

  teardown ->
    close_test_server!

  before_each ->
    truncate_tables Users, Modules, Versions, Rocks

  should_load "/"

  should_load "/about"
  should_load "/m/root"
  should_load "/modules"
  should_load "/manifest"

  should_load "/login"
  should_load "/register"
  should_load "/user/forgot_password"

  -- logged out users shouldn't have access
  should_load "/upload", 302
  should_load "/settings", 302
  should_load "/api_keys/new", 302


  describe "with user", ->
    local user

    request_logged_in = (url, opts={}) ->
      opts.headers or= {}
      for k,v in pairs log_in_user(user)
        opts.headers[k] = v

      request url, opts

    before_each ->
      user = Users\create "leafo", "leafo", "leafo@example.com"

    it "should load upload page", ->
      status, body = request_logged_in "/upload"
      assert.same 200, status

    do_upload = (filename, file_content) ->
      unless pcall -> require "moonrocks.multipart"
        pending "Need moonrocks to run upload spec"
        return false

      import File, encode from require "moonrocks.multipart"

      f = with File filename, "application/octet-stream"
        .content = -> file_content

      data, boundary = encode {
        csrf_token: generate_token nil, user.id
        rockspec_file: f
      }

      request_logged_in "/upload", {
        method: "POST"
        headers: {
          "Content-type": "multipart/form-data; boundary=#{boundary}"
        }

        :data
      }

    it "should upload rockspec", ->
      status, body, headers = do_upload "etlua-dev-1.rockspec", rockspec
      assert.same 302, status
      assert.truthy headers.location\match "/modules/"

      assert.same 1, #Versions\select!


    it "should not upload invalid rockspec", ->
      status = do_upload "etlua-dev-1.rockspec", "hello world"
      assert.same 200, status
      assert.same 0, #Versions\select!


