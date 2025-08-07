# frozen_string_literal: true

require 'spec_helper'
require 'stringio'
require 'logger'
require 'psy_mantis/logger'

RSpec.describe PsyMantis::Logger do
  let(:io) { StringIO.new }

  describe '#initialize' do
    it 'responds to Logger methods' do
      logger = described_class.new(io)

      ::Logger.new(StringIO.new).methods.each do |method|
        expect(logger).to respond_to(method)
      end
    end

    it 'defaults to INFO level if not specified' do
      logger = described_class.new(io)

      expect(logger.level).to eq(::Logger::INFO)
    end

    it 'logs messages at or above the specified level' do
      logger = described_class.new(io, level: ::Logger::WARN)
      logger.info('Info message')
      logger.error('Error message')
      io.rewind
      output = io.read
      expect(output).not_to include('INFO -- : Info message')
      expect(output).to include('ERROR -- : Error message')
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
        env = { 'LOG_LEVEL' => log_level }
        logger = described_class.initialize_from_env(env)
        expect(logger.level).to eq(Object.const_get(expected_const))
      end
    end

    it 'defaults to INFO level if LOG_LEVEL is not set' do
      logger = described_class.initialize_from_env({})
      expect(logger.level).to eq(::Logger::INFO)
    end

    it 'falls back to INFO level if LOG_LEVEL is invalid' do
      env = { 'LOG_LEVEL' => 'FOO' }
      logger = described_class.initialize_from_env(env)
      expect(logger.level).to eq(::Logger::INFO)
    end
  end

  describe '.log_level_from_env' do
    {
      'DEBUG' => 'Logger::DEBUG',
      'INFO' => 'Logger::INFO',
      'WARN' => 'Logger::WARN',
      'ERROR' => 'Logger::ERROR',
      'FATAL' => 'Logger::FATAL'
    }.each do |log_level, expected_const|
      it "returns the log level #{expected_const} for LOG_LEVEL=#{log_level}" do
        env = { 'LOG_LEVEL' => log_level }
        level = described_class.log_level_from_env(env)
        expect(level).to eq(Object.const_get(expected_const))
      end
    end

    it 'defaults to INFO level if LOG_LEVEL is not set' do
      level = described_class.log_level_from_env({})
      expect(level).to eq(::Logger::INFO)
    end

    it 'falls back to INFO level if LOG_LEVEL is invalid' do
      level = described_class.log_level_from_env({ 'LOG_LEVEL' => 'FOO' })
      expect(level).to eq(::Logger::INFO)
    end
  end

  describe '#method_missing' do
    it 'delegates methods to the internal logger' do
      logger = described_class.new(io, level: ::Logger::INFO)
      expect { logger.info('Delegated info') }.not_to raise_error
      io.rewind
      expect(io.read).to include('INFO -- : Delegated info')
    end
  end

  describe '#respond_to_missing?' do
    it 'returns true for methods defined on Logger' do
      logger = described_class.new(io)
      expect(logger.respond_to?(:warn)).to be true
      expect(logger.respond_to?(:non_existing_method)).to be false
    end
  end
end
