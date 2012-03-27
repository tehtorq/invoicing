require 'spec_helper'

describe Invoicing::Invoice do
  include Helpers
  
  before(:each) do
    tear_it_down
    
    @invoice = Invoicing::generate do
      line_item description: "Line Item 1", amount: 1101
      line_item description: "Line Item 2", amount: 5097
      line_item description: "Line Item 3", amount: 1714
      line_item description: "Line Item 4", amount: 20300
    end
  end
  
  it "should be able to add a line item" do
    invoice = Invoicing::generate do
      line_item description: "Line Item 1", amount: 1101
    end
    
    line_items = invoice.line_items
    line_items.count.should == 1
    line_items.first.amount.should == 1101
    line_items.first.description.should == "Line Item 1"
  end
  
  it "should have a total matching the sum of its line item amounts" do
    @invoice.total.should == 28212
  end
  
  it "should create a debit transaction with an amount matching the sum of its line item amounts" do
    @invoice.transactions.length.should == 1
    @invoice.transactions.first.debit?
    @invoice.transactions.first.amount.should == 28212
  end
  
  it "should be able to calculate its balance as the sum of its credit and debit transactions" do
    @invoice.balance.should == -28212
  end
  
  it "should be considered as settled if its balance is zero" do
    @invoice.balance.should_not be_zero
    @invoice.settled?.should be_false
    
    @invoice.add_credit_transaction amount: 28212
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
    @invoice.add_credit_transaction amount: 28212
    @invoice.due_date = Date.today - 1.days
    @invoice.save!
    
    @invoice.overdue?.should be_false
  end
  
  it "should find all invoices which are owing" do
    invoice = Invoicing::generate do
      line_item description: "Line Item 1", amount: 1101
    end
    
    Invoicing::Invoice.owing.count.should == 2    
  end
  
  it "should be able to register multiple references to look up invoices by" do
    invoice = Invoicing::generate do
      payment_reference "Mr. Anderson"
      payment_reference "REF23934"
    end
    
    invoice.payment_references.map(&:reference).should == ["Mr. Anderson", "REF23934"]
  end
  
  it "should be able to find invoices for a given reference" do
    invoice1 = Invoicing::generate do
      payment_reference "Mr. Anderson"
      payment_reference "REF23934"
    end
    
    invoice2 = Invoicing::generate do
      payment_reference "Mr. Anderson"
    end
    
    Invoicing::Invoice.for_payment_reference("Mr. Anderson").should == [invoice1, invoice2]
    Invoicing::Invoice.for_payment_reference("REF23934").should == [invoice1]
    Invoicing::Invoice.for_payment_reference("My Payment").should == []
  end
  
  context "when adding a line item" do
    
    it "should be able to attach an invoiceable item to the line item" do
      item_to_invoice = @invoice.extend(Invoiceable)
      
      invoice = Invoicing::generate do
        line_item item_to_invoice
      end
      
      invoice.line_items.first.invoiceable.should == @invoice
    end
  end
  
end