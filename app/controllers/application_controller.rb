class ApplicationController < ActionController::Base
  include Payload::Controller

  protect_from_forgery with: :null_session

  def dependencies
    @dependencies ||= Payload::RailsLoader.load
  end
end
