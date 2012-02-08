require 'spec_helper'

describe Invoicing::Invoice do
  include Helpers
  
  before(:each) do
    tear_it_down
    
    @invoice = Invoicing::Invoice.new
    @invoice.line_items << Invoicing::LineItem.new(description: "Line Item 1", amount: 11.01)
    @invoice.line_items << Invoicing::LineItem.new(description: "Line Item 2", amount: 50.97)
    @invoice.line_items << Invoicing::LineItem.new(description: "Line Item 3", amount: 17.14)
    @invoice.line_items << Invoicing::LineItem.new(description: "Line Item 4", amount: 203)
    @invoice.save!
  end
  
  it "should have a total matching the sum of its line item amounts" do
    @invoice.total.should == 282.12
  end
  
  it "should create a debit transaction with an amount matching the sum of its line item amounts" do
    @invoice.transactions.length.should == 1
    @invoice.transactions.first.is_a? Invoicing::DebitTransaction
    @invoice.transactions.first.amount.should == 282.12
  end
  
  it "should be able to calculate its balance as the sum of its credit and debit transactions" do
    @invoice.balance.should == -282.12
  end
  
  it "should be considered as settled if its balance is zero" do
    @invoice.balance.should_not be_zero
    @invoice.settled?.should be_false
    
    @invoice.transactions << Invoicing::CreditTransaction.new(amount: 282.12)
    @invoice.save!
    
    @invoice.balance.should be_zero
    @invoice.settled?.should be_true
  end
  
  it "should report as overdue if it is not settled and the due date has past" do
    @invoice.due_date = Date.today - 1.days
    @invoice.save!
    
    @invoice.overdue?.should be_true
  end
  
  it "should not report as overdue if the invoice has been settled" do
    @invoice.transactions << Invoicing::CreditTransaction.new(amount: 282.12)
    @invoice.due_date = Date.today - 1.days
    @invoice.save!
    
    @invoice.overdue?.should be_false
  end
  
  it "should find all invoices which are owing" do
    invoice = Invoicing::Invoice.new
    invoice.line_items << Invoicing::LineItem.new(description: "Line Item 1", amount: 11.01)
    invoice.save!
    
    Invoicing::Invoice.owing.count.should == 2    
  end
  
end