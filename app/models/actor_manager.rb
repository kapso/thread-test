class ActorManager
  def initialize(actor = nil)
    raise 'Not a valid actor object' if actor.present? && !actor.is_a?(Celluloid)    
    @init_actor = actor
    @futures = []
    @actors = []
    @response = []
    @next_response_ctr = 0
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
    if @futures.blank?
      raise 'No actors/requests submitted, cannot process response'
    elsif @next_response_ctr >= @futures.size
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

    actor_arr.each do |actor|
      begin
        actor.terminate if actor.alive?
      rescue => e
        logger.warn "Error: terminating actor #{actor.inspect}: #{e.message}"
      end
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

  private
  def logger
    Rails.logger
  end

  def process_request(index)
    if @actors[index].alive?
      @futures[index].value
    else
      raise "Actor is dead possibly due to some earlier exception, cannot process response: #{@actors[index].inspect}"
    end
  end
end
