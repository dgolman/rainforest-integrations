require 'integrations'
require 'payload_validator'

class EventsController < ApplicationController
  SIGNING_KEY = ENV.fetch('INTEGRATIONS_SIGNING_KEY').freeze
  EVENTS = YAML.load(File.read(Rails.root.join('data', 'events.yml'))).freeze

  before_action :verify_signature, only: [:create]

  def index
    render json: EVENTS
  end

  def create
    begin
      body = MultiJson.load(request.body.read, symbolize_keys: true)
      unless %i(event_type integrations payload).all? { |key| body.key? key }
        return invalid_request
      end

      Integrations.send_event(body)
      render json: { status: 'ok' }, status: :created
    rescue MultiJson::ParseError
      invalid_request('unable to parse request', type: 'parse_error')
    rescue Integrations::Error => e
      invalid_request(e.message, type: e.type)
    rescue PayloadValidator::InvalidPayloadError => e
      invalid_request e.message, type: 'invalid payload'
    end
  end

  private

  def invalid_request(message = 'invalid request', type: 'invalid_request')
    render json: { error: message, type: type }, status: 400
  end

  def verify_signature
    return true if Rails.env.development?

    body_string = request.body.read
    digest = OpenSSL::Digest.new('sha256')
    hmac = OpenSSL::HMAC.hexdigest(digest, SIGNING_KEY, body_string)

    unless request.headers['X-SIGNATURE'] == hmac
      render json: { status: 'unauthorized' }, status: :unauthorized
    end
  end
end
