class HomeController < ApplicationController
  def index
    threads = params[:threads] || 3
    puts "\nUsing threads: #{threads.to_i}"
    render_json data: Car.test_drive(threads.to_i).to_json
  end

  def show
    head :ok
  end
end
