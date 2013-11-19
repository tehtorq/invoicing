require 'spec_helper'

describe Uomi::LineItem do
  include Helpers

  it "should validate that the amount is positive" do
    expect {Uomi::LineItem.create! amount: -0.01}.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Amount must be greater than or equal to 0"
  end

  it "should validate that the amount is specified" do
    expect {Uomi::LineItem.create! amount: nil}.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Amount is not a number, Amount can't be blank"
  end
  
end