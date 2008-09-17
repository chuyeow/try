require File.dirname(__FILE__) + '/spec_helper'

describe "Kernel#retryable" do

  it "should not affect the return value of the block given" do
    retryable { 'foo' }.should == 'foo'
  end

  it "should not affect the return value of the block given when there is a retry" do
    num_calls = 0
    ret_val = retryable_deluxe do
      num_calls += 1
      raise Exception if num_calls == 1 # Raise error only the 1st time.
      'foo'
    end

    num_calls.should == 2
    ret_val.should == 'foo'
  end

  it "uses default options of :tries => 1 and :on => Exception when none is given" do
    num_calls = 0
    lambda {
      retryable do
        num_calls += 1
        raise Exception
      end
    }.should raise_error(Exception)

    num_calls.should == 2
  end

  it "does not retry if none of the retry conditions occur" do
    num_calls = 0
    retryable { num_calls += 1 }

    num_calls.should == 1
  end

  it "uses retries :tries times when the exception to retry on occurs every time" do
    num_calls = 0
    lambda {
      retryable(:tries => 3, :on => StandardError) do
        num_calls += 1
        raise StandardError
      end
    }.should raise_error(StandardError)

    num_calls.should == 4
  end

  it "should respect exception hierarchies (i.e. catch any subclass exceptions)" do
    num_calls = 0
    lambda {
      retryable(:on => StandardError) do
        num_calls += 1
        raise IOError if num_calls == 1 # Raise error only the 1st time.
      end

    }.should_not raise_error(IOError)

    num_calls.should == 2
  end
end

describe "Kernel#retryable_deluxe" do

  it "should not affect the return value of the block given" do
    retryable_deluxe { 'foo' }.should == 'foo'
  end

  it "should not affect the return value of the block given when there is a retry" do
    num_calls = 0
    ret_val = retryable_deluxe do
      num_calls += 1
      raise Exception if num_calls == 1 # Raise error only the 1st time.
      'foo'
    end

    num_calls.should == 2
    ret_val.should == 'foo'
  end

  it "uses default options of :tries => 1 and :on => { :exception => Exception } when none is given" do
    num_calls = 0
    lambda {
      retryable_deluxe do
        num_calls += 1
        raise Exception
      end

    }.should raise_error(Exception)

    num_calls.should == 2
  end

  it "does not retry if none of the retry conditions occur" do
    num_calls = 0
    retryable_deluxe { num_calls += 1 }

    num_calls.should == 1
  end

  it "uses retries :tries times when the exception to retry on occurs every time" do
    num_calls = 0
    lambda {
      retryable_deluxe(:tries => 3, :on => { :exception => StandardError }) do
        num_calls += 1
        raise StandardError
      end
    }.should raise_error(StandardError)

    num_calls.should == 4
  end

  it "should respect exception hierarchies (i.e. catch any subclass exceptions)" do
    num_calls = 0
    lambda {
      retryable_deluxe(:on => { :exception => StandardError }) do
        num_calls += 1
        raise IOError if num_calls == 1 # Raise error only the 1st time.
      end

    }.should_not raise_error(IOError)

    num_calls.should == 2
  end

  it "should retry :tries times when the return value of the block equals :return" do
    num_calls = 0
    retryable_deluxe(:tries => 3, :on => { :return => nil }) do
      num_calls += 1
      nil
    end

    num_calls.should == 4
  end

  it "should retry only 1 time when the return value of the block equals :return only the 1st time" do
    num_calls = 0
    retryable_deluxe(:on => { :return => [] }) do
      num_calls += 1
      num_calls == 1 ? [] : ['not empty']
    end

    num_calls.should == 2
  end

  it "should use both the :exception and :return retry conditions" do
    num_calls = 0

    retryable_deluxe(:tries => 3, :on => { :exception => IOError, :return => nil }) do
      num_calls += 1
      case num_calls
      when 1
        raise IOError
      when 2, 3
        nil
      else
        'some file io'
      end
    end

    num_calls.should == 4
  end
end

describe "Kernel#try" do

  it "should return the value of the 1st lambda/proc/method call if the 1st proc succeeds" do
    try(
      Proc.new { 'foo' },
      Proc.new { 'bar' }
    ).should == 'foo'
  end

  it "should return the value of the 2nd lambda/proc/method call if the 1st fails but the 2nd succeeds" do
    try(
      Proc.new { raise StandardError },
      Proc.new { 1 + 1 }
    ).should == 2
  end

  it "should accept an arbitrary number of arguments and return the value of the last proc if only the last proc succeeds" do
    try(
      Proc.new { raise StandardError },
      Kernel.method('raise'),
      lambda { raise RuntimeError },
      proc { 'last' }
    ).should == 'last'
  end

  it "should allow a fallback value to be passed as the final value" do
    value = try(
      Proc.new { raise StandardError },
      Proc.new { raise StandardError },
      :fallback
    )
    value.should == :fallback
  end

  it "should accept Methods" do
    to_s_of_1_method = 1.method('to_s')
    to_s_of_foo_method = 'foo'.method('to_s')
    try(
      to_s_of_1_method,
      to_s_of_foo_method
    ).should == '1'
  end

  it "should accept procs" do
    test_proc = proc { 1 + 1 }
    try(
      test_proc,
      proc { 'will not come here' }
    ).should == 2
  end

  it "should accept lambdas" do
    try(
      lambda { 1 + 1 },
      lambda { 2 + 2 }
    ).should == 2
  end

  it "should raise a RuntimeError if none of the procs succeed" do
    lambda {
      try(
        Proc.new { raise StandardError },
        Proc.new { raise StandardError }
      )
    }.should raise_error(RuntimeError, 'None of the given procs succeeded')
  end

  it "should raise an ArgumentError if passed less than 2 arguments" do
    lambda {
      try()
    }.should raise_error(ArgumentError, 'try requires at least 2 arguments')

    lambda {
      try(Proc.new {})
    }.should raise_error(ArgumentError, 'try requires at least 2 arguments')
  end
end