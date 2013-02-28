require "vcap/logging"
require "yaml"
require "yajl"
require "json"
require "rest-client"

module CF
  module Harness
  end
end

require "harness/color_helper"
require "harness/harness_helper"
require "harness/cfsession"
require "harness/user"
require "harness/ccng_user_helper"

## support v2
require "harness/space"
require "harness/domain"
