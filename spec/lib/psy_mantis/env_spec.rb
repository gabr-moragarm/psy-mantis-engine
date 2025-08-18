# frozen_string_literal: true

require 'spec_helper'
require 'climate_control'
require_relative '../../../lib/psy_mantis/env'

RSpec.describe PsyMantis::Env do
  describe '.check_required_env!' do
    before do
      allow(Kernel).to receive(:abort) { raise SystemExit, 1 }
    end

    context 'when RACK_ENV is missing' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil)
        allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return('valid_api_key')
        allow(Kernel).to receive(:warn)
      end

      it 'aborts the application' do
        expect { described_class.check_required_env! }.to raise_error(SystemExit)
      end
    end

    context 'when RACK_ENV is invalid' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return('invalid')
        allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return('valid_api_key')
      end

      it 'aborts the application' do
        expect { described_class.check_required_env! }.to raise_error(SystemExit)
      end
    end

    context 'when STEAM_API_KEY is missing' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development')
        allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return(nil)
        allow(Kernel).to receive(:warn)
      end

      it 'aborts the application' do
        expect { described_class.check_required_env! }.to raise_error(SystemExit)
      end
    end

    context 'when all environment variables are valid' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development')
        allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return('valid_api_key')
      end

      it 'does not abort the application' do
        expect { described_class.check_required_env! }.not_to raise_error
      end
    end
  end

  describe '.valid_rack_env?' do
    context 'when RACK_ENV is set to a valid environment' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development') }

      it 'returns true' do
        expect(described_class.valid_rack_env?).to be true
      end
    end

    context 'when RACK_ENV is set to an invalid environment' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('invalid') }

      it 'returns false' do
        expect(described_class.valid_rack_env?).to be false
      end
    end

    context 'when RACK_ENV is not set' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil)
        allow(Kernel).to receive(:warn)
      end

      it 'returns false' do
        expect(described_class.valid_rack_env?).to be false
      end
    end
  end

  describe '.rack_env' do
    context 'when RACK_ENV is set' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development') }

      it 'returns the RACK_ENV value' do
        expect(described_class.rack_env).to eq('development')
      end
    end

    context 'when RACK_ENV is not set' do
      before do
        allow(ENV).to receive(:[]).with('RACK_ENV').and_return(nil)
        allow(Kernel).to receive(:warn)
      end

      it 'returns nil' do
        expect(described_class.rack_env).to be_nil
      end

      it 'warns about the missing RACK_ENV' do
        described_class.rack_env
        expect(Kernel).to have_received(:warn).with(/RACK_ENV is not set!/)
      end
    end
  end

  describe '.steam_api_key' do
    context 'when STEAM_API_KEY is set' do
      before { allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return('valid_api_key') }

      it 'returns the RACK_ENV value' do
        expect(described_class.steam_api_key).to eq('valid_api_key')
      end
    end

    context 'when STEAM_API_KEY is not set' do
      before do
        allow(ENV).to receive(:[]).with('STEAM_API_KEY').and_return(nil)
        allow(Kernel).to receive(:warn)
      end

      it 'returns nil' do
        expect(described_class.steam_api_key).to be_nil
      end

      it 'warns about the missing STEAM_API_KEY' do
        described_class.steam_api_key
        expect(Kernel).to have_received(:warn).with(/STEAM_API_KEY is not set!/)
      end
    end
  end

  describe '.log_level' do
    context 'when LOG_LEVEL is set to a valid level' do
      before { allow(ENV).to receive(:[]).with('LOG_LEVEL').and_return('DEBUG') }

      it 'returns the corresponding Logger constant' do
        expect(described_class.log_level).to eq(::Logger::DEBUG)
      end
    end

    PsyMantis::Env::LOG_LEVELS.each do |log_level, expected_const|
      context "when LOG_LEVEL is set to #{log_level}" do
        before { allow(ENV).to receive(:[]).with('LOG_LEVEL').and_return(log_level) }

        it 'returns the corresponding Logger constant' do
          expect(described_class.log_level).to eq(expected_const)
        end
      end
    end

    context 'when LOG_LEVEL is set to an invalid level' do
      before do
        allow(ENV).to receive(:[]).with('LOG_LEVEL').and_return('INVALID')
        allow(Kernel).to receive(:warn)
      end

      it 'defaults to Logger::INFO' do
        expect(described_class.log_level).to eq(::Logger::INFO)
      end

      it 'warns about the invalid LOG_LEVEL' do
        described_class.log_level
        expect(Kernel).to have_received(:warn).with(/Invalid LOG_LEVEL 'INVALID', defaulting to INFO/)
      end
    end

    context 'when LOG_LEVEL is not set' do
      before do
        allow(ENV).to receive(:[]).with('LOG_LEVEL').and_return(nil)
        allow(Kernel).to receive(:warn)
      end

      it 'defaults to Logger::INFO' do
        expect(described_class.log_level).to eq(::Logger::INFO)
      end

      it 'warns about the missing LOG_LEVEL' do
        described_class.log_level
        expect(Kernel).to have_received(:warn).with(/Invalid LOG_LEVEL 'nil', defaulting to INFO/)
      end
    end
  end

  describe '.host' do
    context 'when HOST is set' do
      it 'returns the HOST value' do
        ClimateControl.modify('HOST' => '127.0.0.1') do
          expect(described_class.host).to eq('127.0.0.1')
        end
      end
    end

    context 'when HOST is not set' do
      it 'returns the default host' do
        ClimateControl.modify('HOST' => nil) do
          expect(described_class.host).to eq('0.0.0.0')
        end
      end
    end
  end

  describe '.container_port' do
    context 'when CONTAINER_PORT is set' do
      it 'returns the CONTAINER_PORT value' do
        ClimateControl.modify('CONTAINER_PORT' => '3000') do
          expect(described_class.container_port).to eq(3000)
        end
      end
    end

    context 'when CONTAINER_PORT is not set' do
      it 'returns the default port' do
        ClimateControl.modify('CONTAINER_PORT' => nil) do
          expect(described_class.container_port).to eq(4567)
        end
      end
    end
  end

  describe '.host_port' do
    context 'when HOST_PORT is set' do
      it 'returns the HOST_PORT value' do
        ClimateControl.modify('HOST_PORT' => '3000') do
          expect(described_class.host_port).to eq(3000)
        end
      end
    end

    context 'when HOST_PORT is not set' do
      it 'returns the default port' do
        ClimateControl.modify('HOST_PORT' => nil) do
          expect(described_class.host_port).to eq(4567)
        end
      end
    end
  end

  describe '.coverage_enabled?' do
    context 'when COVERAGE is set to true' do
      before { allow(ENV).to receive(:[]).with('COVERAGE').and_return('true') }

      it 'returns true' do
        expect(described_class.coverage_enabled?).to be true
      end
    end

    context 'when COVERAGE is set to TRUE' do
      before { allow(ENV).to receive(:[]).with('COVERAGE').and_return('TRUE') }

      it 'is case insensitive and returns true' do
        expect(described_class.coverage_enabled?).to be true
      end
    end

    context 'when COVERAGE is set to false' do
      before { allow(ENV).to receive(:[]).with('COVERAGE').and_return('false') }

      it 'returns false' do
        expect(described_class.coverage_enabled?).to be false
      end
    end

    context 'when COVERAGE is set to an invalid value' do
      before { allow(ENV).to receive(:[]).with('COVERAGE').and_return('invalid') }

      it 'defaults to false' do
        expect(described_class.coverage_enabled?).to be false
      end
    end

    context 'when COVERAGE is not set' do
      before { allow(ENV).to receive(:[]).with('COVERAGE').and_return(nil) }

      it 'returns false' do
        expect(described_class.coverage_enabled?).to be false
      end
    end
  end

  describe '.test_env?' do
    context 'when RACK_ENV is set to test' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('test') }

      it 'returns true' do
        expect(described_class.test_env?).to be true
      end
    end

    context 'when RACK_ENV is not set to test' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development') }

      it 'returns false' do
        expect(described_class.test_env?).to be false
      end
    end
  end

  describe '.development_env?' do
    context 'when RACK_ENV is set to development' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development') }

      it 'returns true' do
        expect(described_class.development_env?).to be true
      end
    end

    context 'when RACK_ENV is not set to development' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('test') }

      it 'returns false' do
        expect(described_class.development_env?).to be false
      end
    end
  end

  describe '.production_env?' do
    context 'when RACK_ENV is set to production' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('production') }

      it 'returns true' do
        expect(described_class.production_env?).to be true
      end
    end

    context 'when RACK_ENV is not set to production' do
      before { allow(ENV).to receive(:[]).with('RACK_ENV').and_return('development') }

      it 'returns false' do
        expect(described_class.production_env?).to be false
      end
    end
  end

  describe '.logs?' do
    context 'when current log level is INFO' do
      before { allow(described_class).to receive(:log_level).and_return(::Logger::INFO) }

      it 'returns false for ::Logger::DEBUG threshold' do
        expect(described_class.logs?(::Logger::DEBUG)).to be false
      end

      it 'returns true for ::Logger::INFO threshold' do
        expect(described_class.logs?(::Logger::INFO)).to be true
      end

      it 'returns true for ::Logger::WARN threshold' do
        expect(described_class.logs?(::Logger::WARN)).to be true
      end
    end

    context 'when current log level is WARN' do
      before { allow(described_class).to receive(:log_level).and_return(::Logger::WARN) }

      it 'returns false for :info threshold' do
        expect(described_class.logs?(:info)).to be false
      end

      it 'returns true for :warn threshold' do
        expect(described_class.logs?(:warn)).to be true
      end

      it 'returns true for :error threshold' do
        expect(described_class.logs?(:error)).to be true
      end
    end

    context 'when current log level is ERROR' do
      before { allow(described_class).to receive(:log_level).and_return(::Logger::ERROR) }

      it "returns false for 'warn' threshold" do
        expect(described_class.logs?('warn')).to be false
      end

      it "returns true for 'error' threshold" do
        expect(described_class.logs?('error')).to be true
      end

      it "returns true for 'fatal' threshold" do
        expect(described_class.logs?('fatal')).to be true
      end
    end

    context 'when an invalid threshold is provided' do
      it 'raises an ArgumentError if threshold is an valid class' do
        expect do
          described_class.logs?(0.4)
        end.to raise_error(ArgumentError, /Threshold must be Integer, String or Symbol/)
      end

      it 'raises an ArgumentError if threshold is an invalid value' do
        expect { described_class.logs?(:invalid) }.to raise_error(ArgumentError, /Unknown log level/)
      end
    end
  end
end
