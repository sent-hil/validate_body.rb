require_relative '../spec_helper'
require_relative '../../middlewares/validate_body'
require 'sinatra/base'

describe ValidateBody do
  context 'without arguments' do
    def app
      Rack::Builder.new do
        use ValidateBody, required_keys: [:a, :b]
        run lambda { |env| [200, {}, []] }
      end
    end

    it 'returns 400 when required field is not in request' do
      post_json('/', something: nil)
      expect(last_response.status).to eq(400)
    end

    it 'returns 400 if not all required fields are in request' do
      post_json('/', a: 1)
      expect(last_response.status).to eq(400)
    end

    it 'returns 200 if request all required keys' do
      post_json('/', a: true, b: true)

      expect(last_response.status).to eq(200)
      expect(last_response.body).to eq('')
    end
  end

  context 'with arguments' do
    def app
      Rack::Builder.new do
        use ValidateBody
        run lambda { |env| [201, {}, []] }
      end
    end

    it 'returns 400 when request body is nil' do
      post('/', nil)
      expect(last_response.status).to eq(400)
    end

    it 'returns 400 when request body is empty json' do
      post_json('/', {})
      expect(last_response.status).to eq(400)
    end

    it 'returns response from original app' do
      post_json('/', anything: true)
      expect(last_response.status).to eq(201)
    end
  end
end
