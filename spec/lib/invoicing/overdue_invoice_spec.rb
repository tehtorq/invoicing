require 'spec_helper'

describe Invoicing::OverdueInvoice do
  include Helpers
  
  before(:each) do
    tear_it_down
  end
   
  it "should find all invoices which are overdue" do
    Invoicing::generate do
      line_item description: "Line Item 1", amount: 1101
      due Time.now
    end
    
    Invoicing::generate do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end
    
    Invoicing::generate do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 0
    end
    
    Invoicing::Invoice.all.each(&:issue!)
    Invoicing::OverdueInvoice.all.count.should == 1
  end
  
  it "should record a late payment against an invoice which is overdue" do
    Invoicing::generate do
      due Time.now
      line_item description: "Line Item 1", amount: 1101
    end
    
    invoice2 = Invoicing::generate do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end
    
    Invoicing::generate do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 0
    end
    
    Invoicing::Invoice.all.each(&:issue!)
    Invoicing::OverdueInvoice.record_late_payments!
    
    Invoicing::LatePayment.count.should == 1
    Invoicing::LatePayment.first.invoice.should == invoice2
    Invoicing::LatePayment.first.amount.should == 1101
    invoice2.late_payment.should == Invoicing::LatePayment.first
  end
  
  it "should default the late payment penalty date to 7 days from the date the late payment was recorded" do
    invoice = Invoicing::generate do
      due Time.now - 1.days
      line_item description: "Line Item 1", amount: 1101
    end

    Invoicing::Invoice.all.each(&:issue!)
    
    Invoicing::OverdueInvoice.record_late_payments!
    invoice.late_payment.penalty_date.should == Date.today.to_time + 7.days
  end
  
end