class ActorManager
  def initialize(actor = nil)
    raise 'Not a valid actor object' if actor.present? && !actor.is_a?(Celluloid)

    @init_actor = actor
    @futures = []
    @actors = []
    @response = []
    @next_response_ctr = 0
    @auto_terminate = true
  end

  def submit(method, *params)
    raise 'Not initialized with a valid actor object' if @init_actor.blank?

    @futures << @init_actor.future(method.to_sym, *params)
    @actors << @init_actor
  end

  def submit_actor(actor, method, *params)
    raise 'Not a valid actor object' if actor.blank? || !actor.is_a?(Celluloid)

    @futures << actor.future(method.to_sym, *params)
    @actors << actor
  end

  def response
    if @futures.blank?
      raise 'No actors/requests submitted, cannot process response'
    elsif @response.size == @futures.size
      @response
    else
      (@next_response_ctr..(@futures.size - 1)).each do |index|
        @response << process_request(index)
        @next_response_ctr += 1
      end

      @response
    end
  end

  def next_response
    logger.warn '[ActorManager] No actors/requests submitted' if @futures.blank?

    if @next_response_ctr >= @futures.size
      nil
    else
      value = process_request(@next_response_ctr)
      @response << value
      @next_response_ctr += 1
      value
    end
  end

  def terminate!
    actor_arr = @actors.uniq

    if actor_arr.present?
      actor_arr.each do |actor|
        begin
          actor.terminate if actor.alive?
        rescue => e
          logger.warn "[ActorManager] Error: terminating actor #{actor.inspect}: #{e.message}"
        end
      end

      @actors.clear
      @futures.clear
      @next_response_ctr = 0
    end
  end

  def tasks_complete?
    actor_arr = @actors.uniq
    raise 'No actors/requests submitted' if actor_arr.blank?

    actor_arr.each do |actor|
      actor.tasks.each { |task| return false if task.running? }
    end

    true
  end

  def each_response
    while resp = next_response
      yield resp
    end
  end

  def any_nil_response?
    response.include? nil
  end

  def set_auto_terminate(auto = true)
    @auto_terminate = auto
  end

  def auto_terminate?
    @auto_terminate
  end

  private
  def logger
    Rails.logger
  end

  def process_request(index)
    if @actors[index].alive?
      value = @futures[index].value
      terminate! if auto_terminate? && index == (@futures.size - 1)
      value
    else
      raise "Actor is dead possibly due to some earlier exception, cannot process response: #{@actors[index].inspect}"
    end
  end
end
