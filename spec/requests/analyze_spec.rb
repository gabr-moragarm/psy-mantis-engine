# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /analyze' do
  context 'when a valid steam_id is provided' do
    before { get '/analyze?steam_id=123456789' }

    it 'returns HTTP status code 200', type: :internal_api do
      expect(last_response.status).to eq(200)
    end

    it 'returns a profile analysis message based on the user\' Steam games', type: :internal_api do
      pending('Define expected response format and analysis logic')
      expect(JSON.parse(last_response.body).keys).to include('analysis')
    end
  end

  context 'when steam_id is missing' do
    before { get '/analyze' }

    it 'returns HTTP status code 400', type: :internal_api do
      expect(last_response.status).to eq(400)
    end

    it 'responds with an appropriate error message', type: :internal_api do
      expect(JSON.parse(last_response.body)['error']).to include('Missing steam_id')
    end
  end
end
