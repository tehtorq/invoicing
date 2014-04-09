require 'spec_helper'

describe Uomi::LineItem do

  it "should validate that the amount is numeric" do
    expect {Uomi::LineItem.create! amount: "fifty bucks"}.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Amount is not a number"
  end

  it "should validate that the amount is specified" do
    expect {Uomi::LineItem.create! amount: nil}.to raise_error ActiveRecord::RecordInvalid, "Validation failed: Amount is not a number, Amount can't be blank"
  end
  
end