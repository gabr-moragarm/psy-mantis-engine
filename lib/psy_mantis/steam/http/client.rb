# frozen_string_literal: true

require_relative './transport'

module PsyMantis
  module Steam
    module HTTP
      # Client for interacting with the Steam Web API and Store API.
      class Client
        BASE_WEB_API_URL = 'https://api.steampowered.com'
        BASE_STORE_URL = 'https://store.steampowered.com'

        PATHS = {
          player_summaries: '/ISteamUser/GetPlayerSummaries/v0002/',
          owned_games: '/IPlayerService/GetOwnedGames/v0001/',
          app_details: '/api/appdetails'
        }.freeze

        AVATAR_PLACEHOLDER_URL = ''

        # Initializes a new Client instance.
        #
        # @param api_key [String] The Steam Web API key.
        # @param transport_opts [Hash] Optional transport configuration.
        # @raise [ArgumentError] If api_key is nil or empty.
        def initialize(api_key, **transport_opts)
          if api_key.nil? || api_key.strip.empty?
            raise ArgumentError, "API key (api_key) is required (given: #{api_key.inspect})"
          end

          @api_key = api_key
          @web_api = Transport.new(base_url: BASE_WEB_API_URL, **transport_opts)
          @store = Transport.new(base_url: BASE_STORE_URL, **transport_opts)
        end

        # Fetches player summaries for the given user IDs.
        #
        # @param user_ids [Array<String>] One or more Steam user IDs.
        # @return [Array<Hash>] An array of normalized player summaries.
        def player_summaries(*user_ids)
          response = @web_api.get(
            PATHS[:player_summaries],
            { key: @api_key, steamids: user_ids.join(',') }
          )&.dig('response', 'players') || []

          response.map { |summary| normalize_player_summary(summary) }
        end

        # Fetches owned games for a given user ID.
        #
        # @param user_id [String] The Steam user ID.
        # @return [Array<Hash>] An array of normalized owned games.
        def owned_games(user_id)
          response = @web_api.get(
            PATHS[:owned_games],
            { key: @api_key, steamid: user_id }
          )&.dig('response', 'games') || []

          response.map { |game| normalize_owned_game(game) }
        end

        # Fetches app details for a given app ID.
        #
        # @param app_id [String, Integer] The Steam app ID.
        # @param country_code [String, nil] Optional country code for pricing.
        # @return [Hash, nil] Normalized app details or nil if not found.
        def app_details(app_id, country_code: nil)
          params = { appids: app_id }
          params[:cc] = country_code if country_code
          response = @store.get(
            PATHS[:app_details],
            params
          )&.dig(app_id.to_s, 'data')

          normalize_app_details(response)
        end

        private

        # Normalizes a player summary hash.
        #
        # @param summary [Hash] The raw player summary.
        # @return [Hash] The normalized player summary.
        def normalize_player_summary(summary)
          {
            steamid: summary['steamid'].to_s,
            personaname: summary.fetch('personaname', ''),
            avatar: summary.fetch('avatar', AVATAR_PLACEHOLDER_URL),
            lastlogoff: summary.fetch('lastlogoff', 0),
            personastate: summary.fetch('personastate', 0),
            timecreated: summary.fetch('timecreated', 0)
          }
        end

        # Normalizes an owned game hash.
        #
        # @param game [Hash] The raw owned game data.
        # @return [Hash] The normalized owned game.
        def normalize_owned_game(game)
          {
            appid: game['appid'].to_s,
            playtime_2weeks: game.fetch('playtime_2weeks', 0),
            playtime_forever: game.fetch('playtime_forever', 0),
            playtime_windows_forever: game.fetch('playtime_windows_forever', 0),
            playtime_mac_forever: game.fetch('playtime_mac_forever', 0),
            playtime_linux_forever: game.fetch('playtime_linux_forever', 0),
            playtime_deck_forever: game.fetch('playtime_deck_forever', 0),
            rtime_last_played: game.fetch('rtime_last_played', 0)
          }
        end

        # Normalizes app details hash.
        #
        # @param details [Hash, nil] The raw app details.
        # @return [Hash, nil] The normalized app details or nil if not present.
        def normalize_app_details(details)
          return nil unless details

          { steam_appid: details['steam_appid'].to_s,
            type: details.fetch('type', ''),
            name: details.fetch('name', ''),
            capsule_image: details.fetch('capsule_image', ''),
            publishers: details.fetch('publishers', []),
            developers: details.fetch('developers', []),
            price_overview: normaliza_price_overview(details),
            genres: normalize_genres(details),
            screenshots: normalize_screenshots(details) }
        end

        # Normalizes the price overview section of app details.
        #
        # @param details [Hash] The app details hash.
        # @return [Hash] The normalized price overview.
        def normaliza_price_overview(details)
          {
            currency: details.dig('price_overview', 'currency'),
            initial: details.dig('price_overview', 'initial'),
            final: details.dig('price_overview', 'final'),
            discount_percent: details.dig('price_overview', 'discount_percent')
          }
        end

        # Normalizes the genres section of app details.
        #
        # @param details [Hash] The app details hash.
        # @return [Array<Hash>] The normalized genres.
        def normalize_genres(details)
          details.fetch('genres', []).map do |genre|
            {
              id: genre.fetch('id', nil).to_s,
              description: genre.fetch('description', '')
            }
          end
        end

        # Normalizes the screenshots section of app details.
        #
        # @param details [Hash] The app details hash.
        # @return [Array<Hash>] The normalized screenshots.
        def normalize_screenshots(details)
          details.fetch('screenshots', []).map do |screenshot|
            {
              id: screenshot.fetch('id', nil).to_s,
              path_full: screenshot.fetch('path_full', '')
            }
          end
        end
      end
    end
  end
end
