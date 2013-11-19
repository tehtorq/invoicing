require 'spec_helper'

describe Uomi::OverdueInvoice do
  include Helpers
  
  before(:each) do
    tear_it_down
  end
   
  it "should find all invoices which are overdue" do
    Uomi::generate_invoice do
      line_item description: "Line Item 1", amount: 1101
      due Time.now
    end
    
    Uomi::generate_invoice do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end
    
    Uomi::generate_invoice do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 0
    end
    
    Uomi::Invoice.all.each(&:issue!)
    Uomi::OverdueInvoice.all.count.should == 1
  end
  
  it "should record a late payment against an invoice which is overdue" do
    Uomi::generate_invoice do
      due Time.now
      line_item description: "Line Item 1", amount: 1101
    end
    
    invoice2 = Uomi::generate_invoice do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end
    
    Uomi::generate_invoice do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 0
    end
    
    Uomi::Invoice.all.each(&:issue!)
    Uomi::OverdueInvoice.record_late_payments!
    
    Uomi::LatePayment.count.should == 1
    Uomi::LatePayment.first.invoice.should == invoice2
    Uomi::LatePayment.first.amount.should == 1101
    invoice2.late_payment.should == Uomi::LatePayment.first
  end
  
  it "should default the late payment penalty date to 7 days from the date the late payment was recorded" do
    invoice = Uomi::generate_invoice do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end

    Uomi::Invoice.all.each(&:issue!)
    
    Uomi::OverdueInvoice.record_late_payments!
    invoice.late_payment.penalty_date.should == Date.today.to_time + 7.days
  end
  
end