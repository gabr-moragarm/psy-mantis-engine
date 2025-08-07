# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GET /analyze' do
  def app
    Sinatra::Application
  end

  it 'returns 400 if steam_id is missing', type: :request do
    get '/analyze'

    expect(last_response.status).to eq(400)
    expect(JSON.parse(last_response.body)['error']).to include('Missing steam_id')
  end

  it 'returns a profile analysis message based on the user\' Steam games', type: :request do
    pending('Define expected response format and analysis logic')

    get '/analyze?steam_id=123456789'

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body).keys).to include('analysis')
  end
end
