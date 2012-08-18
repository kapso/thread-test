class HomeController < ApplicationController
  def index
    threads = params[:threads] || 3
    puts "\nUsing threads: #{threads.to_i}"
    render json: Car.test_drive(threads.to_i)
  end

  def show
    head :ok
  end
end
