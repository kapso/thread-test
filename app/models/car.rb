 class Car
  include Celluloid

  def initialize(start_speed = 10)
    @start_speed = start_speed
    @name = "Audi #{rand(10)}"
  end

  def drive(speed = 80)
    sleep [0.8, 1.5, 2].sample
    raise "what the hell happened here" if speed == 100
    { name: @name, current_speed: speed, start_speed: @start_speed }
  end

  def drive_constant
    sleep [1, 1.5].sample
    { name: @name, current_speed: 100, start_speed: @start_speed }
  end

  def start_speed
    @start_speed
  end

  def self.test_drive(thread_count = 5)
    # Use one actor instance, like UpdateSearch#fetch_updates
    car = Car.new(rand(20))
    am = ActorManager.new(car)
    thread_count.times { am.submit(:drive, rand(90)) }

    # Use different actor instances
    # am = ActorManager.new
    # thread_count.times { am.submit_actor(Car.new(rand(20)), :drive, rand(90)) }

    puts "\n#{thread_count} cars sent for test drive..."

    puts "\nTasks complete: #{am.tasks_complete?}"

    # Blocking call: get all actor's response in a array. Response array order is the same as the "submit" order 
    # resp = am.response

    # Blocking call: Get one response at a time. Order is the same as the "submit" order
    resp = []
    while r = am.next_response
      resp << r
    end

    # Blocking call: Same as next_response
    # resp = []
    # am.each_response do |r|
    #   resp << r
    # end

    puts "\nTasks complete: #{am.tasks_complete?}"

    # Required to terminate actors & GC
    am.terminate!

    resp
  end
end
