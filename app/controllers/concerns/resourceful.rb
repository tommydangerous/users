module Resourceful
  extend ActiveSupport::Concern

  included do
    include Actions
    include Callbacks
  end

  private

  def require_params
    copy = params.dup
    unless request.headers["CONTENT_TYPE"] == "application/json"
      copy[resource.name] = params.to_hash.except(
        *%w(action controller format id)
      )
    end
    copy.require resource.name
  end

  def resource_params
    rescue_missing_params do
      hash = require_params
      if self.class.resource_params
        hash.permit self.class.resource_params
      else
        hash.permit!
      end
    end
  end

  def record_id
    params[resource.foreign_key] || params[:id]
  end

  def resource
    @resource ||= dependencies[:resource].new self
  end

  def rescue_missing_params
    sanitize_params
    yield
  rescue ActionController::ParameterMissing
    ActionController::Parameters.new
  end

  def sanitize_params
  end

  def search_params
    rescue_missing_params do
      hash = params.require :q

      if self.class.search_params
        hash.permit self.class.search_params
      else
        hash.permit!
      end
    end
  end

  module Actions
    extend ActiveSupport::Concern

    included do
      helper_method :collection, :record
    end

    def create
      record.save
      render_record
    end

    def destroy
      record.destroy
      render_record
    end

    def edit
      render_record
    end

    def index
      render_collection
    end

    def new
      render_record
    end

    def show
      render_record
    end

    def update
      record.update resource_params
      render_record
    end

    private

    attr_reader :collection, :record

    def render_collection
      respond_with collection
    end

    def render_record
      options = { location: resource_location }.compact
      respond_with record, options
    end

    def resource_location
    end
  end

  module Callbacks
    extend ActiveSupport::Concern

    included do
      before_action :build_record, only: %i(create new)
      before_action :find_record,  only: %i(destroy edit show update)
      before_action :find_collection, only: %(index)

      unless Rails.env.development?
        rescue_from ActiveRecord::RecordNotFound, with: :not_found
        rescue_from Payload::UndefinedDependencyError, with: :not_found
      end
    end

    private

    def build_record
      @record ||= resource.build resource_params
    end

    def find_record
      @record ||= resource.find(record_id) || not_found
    end

    def find_collection
      @collection ||= search
    end

    def not_found
      render nothing: true, status: :not_found
    end

    def search
      resource.search(:ransack, search_params).result
    end
  end

  module ClassMethods
    def resource_params(*args)
      if args.any?
        @resource_params = args.flatten
      end

      @resource_params
    end

    def search_params(*args)
      if args.any?
        @search_params = args.flatten
      end

      @search_params
    end
  end
end
