# frozen_string_literal: true

class CloseModalController < ApplicationController
  def index
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove('modal') }
      format.html { redirect_back fallback_location: root_path }
    end
  end
end
