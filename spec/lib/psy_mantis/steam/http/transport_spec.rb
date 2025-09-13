# frozen_string_literal: true

require 'spec_helper'
require 'webmock/rspec'
require 'json'
require_relative '../../../../../lib/psy_mantis/steam/http/transport'

RSpec.describe PsyMantis::Steam::HTTP::Transport do
  subject(:transport) { described_class.new(base_url: base_url) }

  let(:base_url) { 'http://example.com' }
  let(:path) { '/test' }

  def stub_get_request
    stub_request(:get, "#{base_url}#{path}")
  end

  describe '#initialize' do
    it 'throws an ArgumentError if base_url is not a String' do
      expect { described_class.new(base_url: nil) }.to raise_error(ArgumentError, /base_url/i)
    end

    it 'throws an ArgumentError if base_url is an empty String' do
      expect { described_class.new(base_url: '')  }.to raise_error(ArgumentError, /base_url/i)
    end
  end

  describe '#get' do
    it 'performs a GET request with the provided path and parameters' do
      stub = stub_get_request.with(query: { param: 'value' })

      transport.get(path, { param: 'value' })

      expect(stub).to have_been_requested
    end

    it 'parses and returns the JSON response body' do
      stub_get_request.to_return(headers: { 'Content-Type' => 'application/json' }, body: '{ "data": "value" }')

      response = transport.get(path)

      expect(response).to eq({ 'data' => 'value' })
    end

    it 'raises Unauthorized error for 401 response' do
      stub_get_request.to_return(status: 401)

      expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::Unauthorized)
    end

    it 'raises Forbidden error for 403 response' do
      stub_get_request.to_return(status: 403)

      expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::Forbidden)
    end

    it 'raises NotFound error for 404 response' do
      stub_get_request.to_return(status: 404)

      expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::NotFound)
    end

    it 'raises Timeout error for request timeouts' do
      stub_get_request
        .to_timeout

      expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::Timeout)
    end

    context 'when 429 Too Many Requests is returned' do
      let(:options) { { max_retries: 1, base_backoff: 0.5, jitter: false } }
      let(:retry_after) { '2' }

      it 'waits for the specified duration in Retry-After header' do
        stub_get_request.to_return([{ status: 429, headers: { 'Retry-After' => retry_after } }, { status: 200 }])
        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(transport).to have_received(:sleep_for).with(retry_after.to_i)
      end

      it 'uses backoff when response has no Retry-After' do
        stub_get_request.to_return([{ status: 429 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(transport).to have_received(:sleep_for).with(options[:base_backoff])
      end

      it 'uses exponential backoff when response has no Retry-After' do
        stub_get_request.to_return([{ status: 429 }, { status: 429 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options, max_retries: 2)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(transport).to have_received(:sleep_for).with(2 * options[:base_backoff])
      end

      it 'retries for max_retries times' do
        stub = stub_get_request.to_return([{ status: 429 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(stub).to have_been_requested.times(1 + options[:max_retries])
      end

      it 'raises RateLimited error when max_retries is exceeded' do
        stub_get_request.to_return(2.times.map { { status: 429, body: '' } })

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::RateLimited)
      end
    end

    context 'when 500 Too Many Requests is returned' do
      let(:options) { { max_retries: 1, base_backoff: 0.5, jitter: false } }

      it 'waits for backoff duration' do
        stub_get_request.to_return([{ status: 500 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(transport).to have_received(:sleep_for).with(options[:base_backoff])
      end

      it 'waits for exponential backoff when multiple 500 are returned' do
        stub_get_request.to_return([{ status: 500 }, { status: 500 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options, max_retries: 2)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(transport).to have_received(:sleep_for).with(2 * options[:base_backoff])
      end

      it 'retries for max_retries times' do
        stub = stub_get_request.to_return([{ status: 500 }, { status: 200 }])

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        transport.get(path)

        expect(stub).to have_been_requested.times(1 + options[:max_retries])
      end

      it 'raises ServerError error when max_retries is exceeded' do
        stub_get_request.to_return(2.times.map { { status: 500, body: '' } })

        transport = described_class.new(base_url: base_url, **options)
        allow(transport).to receive(:sleep_for)

        expect { transport.get(path) }.to raise_error(PsyMantis::Steam::HTTP::Errors::ServerError)
      end
    end
  end
end
