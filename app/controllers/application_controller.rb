class ApplicationController < ActionController::Base
  protect_from_forgery

  def render_json(content, options = {})
    render options.merge(json: content)
  end
end
