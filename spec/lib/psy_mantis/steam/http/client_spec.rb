# frozen_string_literal: true

require 'spec_helper'
require 'json'
require 'webmock/rspec'
require_relative '../../../../../lib/psy_mantis/steam/http/client'
require_relative '../../../../../lib/psy_mantis/steam/http/errors'
require_relative '../../../../../lib/psy_mantis/steam/http/transport'

RSpec.describe PsyMantis::Steam::HTTP::Client do
  let(:api_key) { 'TEST_KEY' }
  let(:steam_user_id) { '76561198000000000' }

  describe '#initialize' do
    it 'correctly initialize api_key istance variable' do
      expect(described_class.new(api_key).instance_variable_get(:@api_key)).to eq(api_key)
    end

    it 'correctly initialize web_api Transport instance variable' do
      expect(described_class.new(api_key).instance_variable_get(:@web_api)).to be_a(PsyMantis::Steam::HTTP::Transport)
    end

    it 'correctly initialize store Transport instance variable' do
      expect(described_class.new(api_key).instance_variable_get(:@store)).to be_a(PsyMantis::Steam::HTTP::Transport)
    end

    it 'throws an ArgumentError if api_key is not a String' do
      expect { described_class.new(nil) }.to raise_error(ArgumentError, /api_key/i)
    end

    it 'throws an ArgumentError if api_key is an empty String' do
      expect { described_class.new('')  }.to raise_error(ArgumentError, /api_key/i)
    end
  end

  describe '#player_summaries' do
    let(:url) do
      "#{PsyMantis::Steam::HTTP::Client::BASE_WEB_API_URL}#{PsyMantis::Steam::HTTP::Client::PATHS[:player_summaries]}"
    end
    let(:fixture) { File.read('spec/fixtures/steam/player_summaries.json') }
    let(:player_summaries_query) { { key: api_key, steamids: steam_user_id } }

    RSpec::Matchers.define :match_player_summaries_contract do
      match do |result|
        result.is_a?(Array) &&
          result.all? do |h|
            h.is_a?(Hash) &&
              h.key?(:steamid) && h[:steamid].is_a?(String) &&
              h.key?(:personaname) && h[:personaname].is_a?(String) &&
              h.key?(:avatar) && h[:avatar].is_a?(String) &&
              h.key?(:lastlogoff) && h[:lastlogoff].is_a?(Integer) &&
              h.key?(:personastate) && h[:personastate].is_a?(Integer) &&
              h.key?(:timecreated) && h[:timecreated].is_a?(Integer)
          end
      end
    end

    def stub_player_summaries(status: 200, body: fixture, query_overrides: {})
      query = player_summaries_query.merge(query_overrides)

      stub_request(:get, url)
        .with(query: query)
        .to_return(status: status, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'performs a GET request to the correct URL with the correct parameters' do
      stub = stub_player_summaries
      client = described_class.new(api_key)

      client.player_summaries(steam_user_id)

      expect(stub).to have_been_requested
    end

    it 'returns a normalized array of player summaries (contract)' do
      stub_player_summaries
      client = described_class.new(api_key)

      player_summaries = client.player_summaries(steam_user_id)

      expect(player_summaries).to match_player_summaries_contract
    end

    it 'returns empty array when Steam responds without player summaries' do
      stub_player_summaries(body: { response: {} }.to_json)

      client = described_class.new(api_key)
      expect(client.player_summaries(steam_user_id)).to eq([])
    end

    it 'returns empty array when Steam responds without a body' do
      stub_player_summaries(body: nil.to_json)

      client = described_class.new(api_key)
      expect(client.player_summaries(steam_user_id)).to eq([])
    end
  end

  describe '#owned_games' do
    let(:url) do
      "#{PsyMantis::Steam::HTTP::Client::BASE_WEB_API_URL}#{PsyMantis::Steam::HTTP::Client::PATHS[:owned_games]}"
    end
    let(:fixture) { File.read('spec/fixtures/steam/owned_games.json') }

    RSpec::Matchers.define :match_games_contract do
      match do |result|
        result.is_a?(Array) &&
          result.all? do |h|
            h.is_a?(Hash) &&
              h.key?(:appid) && h[:appid].is_a?(String) &&
              h.key?(:playtime_2weeks) && h[:playtime_2weeks].is_a?(Integer) &&
              h.key?(:playtime_forever) && h[:playtime_forever].is_a?(Integer) &&
              h.key?(:playtime_windows_forever) && h[:playtime_windows_forever].is_a?(Integer) &&
              h.key?(:playtime_mac_forever) && h[:playtime_mac_forever].is_a?(Integer) &&
              h.key?(:playtime_linux_forever) && h[:playtime_linux_forever].is_a?(Integer) &&
              h.key?(:playtime_deck_forever) && h[:playtime_deck_forever].is_a?(Integer) &&
              h.key?(:rtime_last_played) && h[:rtime_last_played].is_a?(Integer)
          end
      end
    end

    def owned_games_query
      {
        key: api_key,
        steamid: steam_user_id
      }
    end

    def stub_owned_games(status: 200, body: fixture, query_overrides: {})
      query = owned_games_query.merge(query_overrides)

      stub_request(:get, url)
        .with(query: query)
        .to_return(status: status, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'performs a GET request to the correct URL with the correct parameters' do
      stub = stub_owned_games
      client = described_class.new(api_key)

      client.owned_games(steam_user_id)

      expect(stub).to have_been_requested
    end

    it 'returns a normalized array of games (contract)' do
      stub_owned_games
      client = described_class.new(api_key)

      games = client.owned_games(steam_user_id)

      expect(games).to match_games_contract
    end

    it 'returns empty array when Steam responds without game list' do
      stub_owned_games(body: { response: { game_count: 0 } }.to_json)

      client = described_class.new(api_key)
      expect(client.owned_games(steam_user_id)).to eq([])
    end

    it 'returns empty array when Steam responds without a body' do
      stub_owned_games(body: nil.to_json)

      client = described_class.new(api_key)
      expect(client.owned_games(steam_user_id)).to eq([])
    end
  end

  describe '#app_details' do
    let(:url) do
      "#{PsyMantis::Steam::HTTP::Client::BASE_STORE_URL}#{PsyMantis::Steam::HTTP::Client::PATHS[:app_details]}"
    end
    let(:fixture) { File.read('spec/fixtures/steam/app_details.json') }
    let(:steam_app_id) { '391540' }

    RSpec::Matchers.define :match_app_details_contract do
      def hash_value_is_a?(hash, key, type)
        hash.key?(key) && hash[key].is_a?(type)
      end

      def hash_value_is_an_array_of?(hash, key, type)
        hash_value_is_a?(hash, key, Array) && hash[key].all? { |item| item.is_a?(type) }
      end

      match do |result|
        result.is_a?(Hash) &&
          hash_value_is_a?(result, :steam_appid, String) &&
          hash_value_is_a?(result, :type, String) &&
          hash_value_is_a?(result, :name, String) &&
          hash_value_is_a?(result, :capsule_image, String) &&
          hash_value_is_an_array_of?(result, :publishers, String) &&
          hash_value_is_an_array_of?(result, :developers, String) &&
          hash_value_is_a?(result, :price_overview, Hash) &&
          hash_value_is_a?(result[:price_overview], :currency, String) &&
          hash_value_is_a?(result[:price_overview], :initial, Integer) &&
          hash_value_is_a?(result[:price_overview], :final, Integer) &&
          hash_value_is_a?(result[:price_overview], :discount_percent, Integer) &&
          hash_value_is_an_array_of?(result, :genres, Hash) &&
          result[:genres].all? do |g|
            hash_value_is_a?(g, :id, String) && hash_value_is_a?(g, :description, String)
          end &&
          hash_value_is_an_array_of?(result, :screenshots, Hash) &&
          result[:screenshots].all? do |s|
            hash_value_is_a?(s, :id, String) && hash_value_is_a?(s, :path_full, String)
          end
      end
    end

    def stub_app_details(status: 200, body: fixture, query_overrides: {})
      query = { appids: steam_app_id }.merge(query_overrides)

      stub_request(:get, url)
        .with(query: query)
        .to_return(status: status, body: body, headers: { 'Content-Type' => 'application/json' })
    end

    it 'performs a GET request to the correct URL with the correct parameters' do
      stub = stub_app_details(query_overrides: { cc: 'CH' })
      client = described_class.new(api_key)

      client.app_details(steam_app_id, country_code: 'CH')

      expect(stub).to have_been_requested
    end

    it 'returns the normalized details of the app/game' do
      stub_app_details
      client = described_class.new(api_key)

      details = client.app_details(steam_app_id)

      expect(details).to match_app_details_contract
    end

    it 'returns nil when Steam doesn\'t responds with the game details' do
      stub_app_details(body: { response: {} }.to_json)

      client = described_class.new(api_key)
      expect(client.app_details(steam_app_id)).to be_nil
    end

    it 'returns empty array when Steam responds without a body' do
      stub_app_details(body: nil.to_json)

      client = described_class.new(api_key)
      expect(client.app_details(steam_app_id)).to be_nil
    end
  end
end
