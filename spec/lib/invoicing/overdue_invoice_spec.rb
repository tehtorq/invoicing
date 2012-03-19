require 'spec_helper'

describe Invoicing::OverdueInvoice do
  include Helpers
  
  before(:each) do
    tear_it_down
  end
   
  it "should find all invoices which are overdue" do
    invoice = Invoicing::Invoice.new(due_date: Time.now)
    invoice.add_line_item description: "Line Item 1", amount: 1101
    invoice.save!
    
    invoice = Invoicing::Invoice.new(due_date: Time.now - 1.days)
    invoice.add_line_item description: "Line Item 1", amount: 1101
    invoice.save!
    
    invoice = Invoicing::Invoice.new(due_date: Time.now - 1.days)
    invoice.add_line_item description: "Line Item 1", amount: 0
    invoice.save!
    
    Invoicing::OverdueInvoice.all.count.should == 1
  end
  
  it "should record a late payment against an invoice which is overdue" do
    invoice1 = Invoicing::Invoice.new(due_date: Time.now)
    invoice1.add_line_item description: "Line Item 1", amount: 1101
    invoice1.save!
    
    invoice2 = Invoicing::Invoice.new(due_date: Time.now - 1.days)
    invoice2.add_line_item description: "Line Item 1", amount: 1101
    invoice2.save!
    
    invoice3 = Invoicing::Invoice.new(due_date: Time.now - 1.days)
    invoice3.add_line_item description: "Line Item 1", amount: 0
    invoice3.save!
    
    Invoicing::OverdueInvoice.record_late_payments!
    
    Invoicing::LatePayment.count.should == 1
    Invoicing::LatePayment.first.invoice.should == invoice2
    Invoicing::LatePayment.first.amount.should == 1101
    invoice2.late_payment.should == Invoicing::LatePayment.first
  end
  
  it "should default the late payment penalty date to 7 days from the date the late payment was recorded" do
    invoice = Invoicing::Invoice.new(due_date: Time.now - 1.days)
    invoice.add_line_item description: "Line Item 1", amount: 1101
    invoice.save!
    
    Invoicing::OverdueInvoice.record_late_payments!
    invoice.late_payment.penalty_date.should == Date.today.to_time + 7.days
  end
  
end