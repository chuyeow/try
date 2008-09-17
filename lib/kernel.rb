module Kernel

  # Options:
  # * :tries - Number of retries to perform. Defaults to 1.
  # * :on - The Exception on which a retry will be performed. Defaults to Exception, which retries on any Exception.
  #
  # Example
  # =======
  #   retryable(:tries => 1, :on => OpenURI::HTTPError) do
  #     # your code here
  #   end
  #
  def retryable(options = {}, &block)
    opts = { :tries => 1, :on => Exception }.merge(options)

    retry_exception, retries = opts[:on], opts[:tries]

    begin
      return yield
    rescue retry_exception
      retry if (retries -= 1) > 0
    end

    yield
  end

  # Options:
  # * :tries - Number of retries to perform. Defaults to 1.
  # * :on - The condition on which a retry will be performed. Can be a hash with an :exception and/or
  #         :return key. Defaults to <tt>{ :exception => Exception }</tt>, which retries on any Exception.
  #
  # Examples
  # ========
  #   retryable_deluxe(:tries => 1, :on => { :exception => OpenURI::HTTPError }) do
  #     # your code here
  #   end
  #
  #   retryable_deluxe(:tries => 5, :on => { :return => nil }) { puts "working..." }
  #
  #   retryable_deluxe(:on => { :exception => StandardError, :return => nil }) do
  #     # your code here
  #   end
  #
  # TODO Damn thing needs a lot of DRY love.
  # TODO Allow a proc for :on option.
  def retryable_deluxe(options = {}, &block)
    opts = {
      :on => { :exception => Exception }
    }.merge(options)

    retries = options[:tries] || 1
    retry_return = opts[:on].has_key?(:return)
    retry_exception = opts[:on][:exception] || (Exception unless retry_return)
    retry_return_val = opts[:on][:return]

    if retry_exception && !retry_return
      return retryable(:tries => retries, :on => retry_exception, &block)
    elsif retry_return && retry_return
      begin
        ret = yield
        if ret == retry_return_val
          (retries - 1).times do
            ret = yield
            return ret unless ret == retry_return_val
          end
        else
          return ret
        end
      rescue retry_exception
        (retries - 1).times do
          ret = yield
          if ret == retry_return_val
            (retries -1).times do
              ret = yield
              return ret unless ret == retry_return_val
            end
          else
            return ret
          end rescue retry_exception
        end
      end
    elsif retry_return
      ret = yield
      if ret == retry_return_val
        (retries -1).times do
          ret = yield
          return ret unless ret == retry_return_val
        end
      else
        return ret
      end
    end

    yield
  end

  def try(*these)
    raise ArgumentError, 'try requires at least 2 arguments' if these.size <= 1
    fallback = these.pop unless these.last.respond_to?(:call)
    these.each { |candidate| begin return candidate.call rescue next end }
    fallback || raise(RuntimeError, 'None of the given procs succeeded')
  end

  def __caller_lines__(file, line, size = 4)
    lines = File.readlines(file)
    current = line.to_i - 1

    first = current - size
    first = 0 if first < 0

    last = current + size
    last = lines.size if last > lines.size

    log = lines[first..last]

    area = []
    log.each_with_index do |line, index|
      index = index + first + 1
      area << [index, line.chomp, index == current + 1]
    end

    area
  end
end