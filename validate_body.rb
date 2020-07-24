require 'sorbet-runtime'

# ValidateBody is a middleware to ensure POST/PUT request have body and
# optionally that body contains given keys. If the request is not valid,
# it returns a 400.
#
# This assumes the request is an `application/json` request.
#
# Example:
#   # checks for all POST/PUT requests, there's valid, non empty JSON in body.
#   use(ValidateBody)
#
#   # checks for all POST/PUT requests, there's `product_id` in body.
#   use(ValidateBody, required_keys: [:product_id])
class ValidateBody
  extend T::Sig

  # this can be a class or Proc since both implement Rack spec
  attr_reader :app

  sig {returns(T::Array[Symbol])}
  attr_reader :required_keys

  sig {returns(Rack::Request)}
  attr_reader :request

  def initialize(app, required_keys: [])
    @app = app
    @required_keys = required_keys
  end

  sig {params(env: Hash).returns(Array)}
  def call(env)
    @request = Rack::Request.new(env)

    if !request.post? && !request.put? # only POST and PUT requests
      return app_call_after_rewind(env)
    elsif empty_body? || not_all_required_keys?
      return halt_request
    else
      return app_call_after_rewind(env)
    end
  end

  private

  sig {params(env: Hash).returns(Array)}
  def app_call_after_rewind(env)
    request.body.rewind # be kind, rewind
    app.call(env)
  end

  sig {returns(T::Boolean)}
  def empty_body?
    request_body == '' || request_json_body.empty?
  end

  sig {returns(T::Boolean)}
  def not_all_required_keys?
    # json keys are strings, hence `&:to_sym`
    !(required_keys-request_json_body.keys.map(&:to_sym)).empty?
  end

  sig {returns(Array)}
  def halt_request
    Rack::Response.new([], 400, {}).finish
  end

  sig {returns(String)}
  def request_body
    @request_body ||= begin
      request.body.rewind # in case some other middleware read it already
      request.body.read
    end
  end

  sig {returns(Hash)}
  def request_json_body
    @request_json_body ||= JSON.parse(request_body)
  end
end
