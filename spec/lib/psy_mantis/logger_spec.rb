# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'logger'
require_relative '../../../lib/psy_mantis/logger'
require 'climate_control'

RSpec.describe PsyMantis::Logger do
  let(:io) { StringIO.new }

  describe '#initialize' do
    it 'responds to Logger methods' do
      logger = described_class.new(io)

      ::Logger.new(StringIO.new).methods.each do |method|
        expect(logger).to respond_to(method)
      end
    end

    context 'when LOG_LEVEL is not specified' do
      it 'defaults to INFO level' do
        logger = described_class.new(io)

        expect(logger.level).to eq(::Logger::INFO)
      end
    end

    it 'logs messages at LOG_LEVEL' do
      logger = described_class.new(io, level: ::Logger::INFO)
      logger.info('Info message')
      io.rewind
      output = io.read
      expect(output).to include('INFO -- : Info message')
    end

    it 'logs messages above LOG_LEVEL' do
      logger = described_class.new(io, level: ::Logger::WARN)
      logger.error('Error message')
      io.rewind
      output = io.read
      expect(output).to include('ERROR -- : Error message')
    end

    it 'doesn\'t log messages below LOG_LEVEL' do
      logger = described_class.new(io, level: ::Logger::WARN)
      logger.info('Info message')
      io.rewind
      output = io.read
      expect(output).not_to include('INFO -- : Info message')
    end
  end

  describe '.initialize_from_env' do
    {
      'DEBUG' => 'Logger::DEBUG',
      'INFO' => 'Logger::INFO',
      'WARN' => 'Logger::WARN',
      'ERROR' => 'Logger::ERROR',
      'FATAL' => 'Logger::FATAL'
    }.each do |log_level, expected_const|
      it "returns a logger with level #{expected_const} for LOG_LEVEL=#{log_level}" do
        ClimateControl.modify('LOG_LEVEL' => log_level) do
          logger = described_class.initialize_from_env
          expect(logger.level).to eq(Object.const_get(expected_const))
        end
      end
    end

    it 'defaults to INFO level if LOG_LEVEL is not set' do
      ClimateControl.modify('LOG_LEVEL' => nil) do
        logger = described_class.initialize_from_env
        allow(Kernel).to receive(:warn)
        expect(logger.level).to eq(::Logger::INFO)
      end
    end

    it 'falls back to INFO level if LOG_LEVEL is invalid' do
      ClimateControl.modify('LOG_LEVEL' => 'FOO') do
        logger = described_class.initialize_from_env
        allow(Kernel).to receive(:warn)
        expect(logger.level).to eq(::Logger::INFO)
      end
    end
  end

  describe '#method_missing' do
    # It's also a test to check if the following tests are false positives
    it 'is called when a missing method is called' do
      logger = described_class.new(io, level: ::Logger::INFO)
      allow(logger).to receive(:method_missing).and_call_original
      logger.info('Delegated info')
      io.rewind
      expect(logger).to have_received(:method_missing).with(:info, 'Delegated info')
    end

    it 'delegates methods to the internal logger' do
      logger = described_class.new(io, level: ::Logger::INFO)
      logger.info('Delegated info')
      io.rewind
      expect(io.read).to include('INFO -- : Delegated info')
    end
  end

  describe '#respond_to_missing?' do
    it 'responds to methods defined on ruby Logger' do
      logger = described_class.new(io)
      expect(logger.respond_to?(:warn)).to be true
    end

    it 'doesn\'t respond to methods not defined on itself or ruby Logger' do
      logger = described_class.new(io)
      expect(logger.respond_to?(:non_existing_method)).to be false
    end
  end
end
