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

      payment_reference "REF123"
      decorate_with tenant_name: "Peter"
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

  context "an issued invoice" do

    before(:each) do
      @invoice.issue!
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

  end

  context "searching for sets of invoices" do

    before(:each) do
      tear_it_down
    end

    it "should find draft invoices" do
      issued_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end

      issued_invoice.issue!

      draft_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end
      
      Invoicing::Invoice.draft.count.should == 1
      Invoicing::Invoice.draft.first.should == draft_invoice
    end

    it "should find issued invoices" do
      issued_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end

      issued_invoice.issue!

      other_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end
      
      Invoicing::Invoice.issued.count.should == 1
      Invoicing::Invoice.issued.first.should == issued_invoice
    end

    it "should find owing invoices" do
      owing_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end

      owing_invoice.issue!

      other_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end
      
      Invoicing::Invoice.owing.count.should == 1
      Invoicing::Invoice.owing.first.should == owing_invoice
    end

    it "should find settled invoices" do
      settled_invoice = Invoicing::generate do
      end

      settled_invoice.issue!

      other_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end
      
      Invoicing::Invoice.settled.count.should == 1
      Invoicing::Invoice.settled.first.should == settled_invoice
    end

    it "should find voided invoices" do
      voided_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end

      voided_invoice.issue!
      voided_invoice.void!

      other_invoice = Invoicing::generate do
        line_item description: "Line Item 1", amount: 1101
      end
      
      Invoicing::Invoice.voided.count.should == 1
      Invoicing::Invoice.voided.first.should == voided_invoice
    end

  end

  context "specifying an invoice number" do
  
    it "should default the invoice number to a format of INV{invoice id}" do
      @invoice.invoice_number.should == "INV#{@invoice.id}"
    end

    it "should allow a specific invoice number to be specified" do
      invoice = Invoicing::generate do
        numbered "CUSTOMREF123"
      end
      
      invoice.invoice_number.should == "CUSTOMREF123"
    end

    it "should allow a custom invoice number format to be specified containing the invoice id" do
      invoice = Invoicing::generate do
        numbered "CUSTOMREF{id}"
      end

      invoice.invoice_number.should == "CUSTOMREF#{invoice.id}"
    end

    it "should validate that the invoice number is unique per seller" do
      seller = Invoicing::Seller.create!

      invoice = Invoicing::generate do
        numbered "CUSTOMREF123"
        from seller
      end

      expect {
        invoice = Invoicing::generate do
          numbered "CUSTOMREF123"
          from seller
        end
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Invoice number has already been taken")
    end

    it "should allow two invoices with the same invoice number, but from different sellers" do
      first_seller = Invoicing::Seller.create!

      invoice = Invoicing::generate do
        numbered "CUSTOMREF123"
        from first_seller
      end

      second_seller = Invoicing::Seller.create!

      expect {
        invoice = Invoicing::generate do
          numbered "CUSTOMREF123"
          from second_seller
        end
      }.to_not raise_error
    end

  end
  
  it "should be able to register multiple payment references to look up invoices by" do
    invoice = Invoicing::generate do
      payment_reference "Mr. Anderson"
      payment_reference "REF23934"
    end
    
    invoice.payment_references.map(&:reference).should == ["Mr. Anderson", "REF23934"]
  end
  
  it "should be able to specify the seller" do
    seller = Invoicing::Seller.create!
    
    invoice = Invoicing::generate do
      from seller
    end
    
    invoice.seller.should == seller
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
      item_to_invoice = @invoice.extend(Invoicing::Invoiceable)
      
      invoice = Invoicing::generate do
        line_item item_to_invoice
      end
      
      invoice.line_items.first.invoiceable.should == @invoice
    end
  end
  
  it "should be able to add decoration data to the invoice" do
    item_to_invoice = @invoice.extend(Invoicing::Invoiceable)

    decoration = {invoicee: "Bob Jones"}
    
    invoice = Invoicing::generate do
      line_item item_to_invoice
      decorate_with decoration
    end
    
    invoice.decorator.data.should == {invoicee: "Bob Jones"}
  end

  context "destroying an invoice" do

    it "should destroy its associated line items" do
      Invoicing::LineItem.create! amount: 0
      Invoicing::LineItem.count.should == 5
      @invoice.destroy
      Invoicing::LineItem.count.should == 1
    end

    it "should destroy its associated transactions" do
      @invoice.issue!
      Invoicing::Transaction.create!
      Invoicing::Transaction.count.should == 2
      @invoice.destroy
      Invoicing::Transaction.count.should == 1
    end

    it "should destroy its associated payment_references" do
      Invoicing::PaymentReference.create!
      Invoicing::PaymentReference.count.should == 2
      @invoice.destroy
      Invoicing::PaymentReference.count.should == 1
    end

    it "should destroy its associated late payments" do
      Invoicing::LatePayment.create!
      Invoicing::LatePayment.create! invoice_id: @invoice.id
      Invoicing::LatePayment.count.should == 2
      @invoice.destroy
      Invoicing::LatePayment.count.should == 1
    end

    it "should destroy its associated decorator" do
      Invoicing::InvoiceDecorator.create!
      Invoicing::InvoiceDecorator.count.should == 2
      @invoice.destroy
      Invoicing::InvoiceDecorator.count.should == 1
    end

  end

  context "giving the invoice state" do

    context "new invoice" do
      it "should default to the state draft" do
        @invoice.should be_draft
      end

      it "should raise an error when attempting to void an invoice in the draft state" do
        lambda{ @invoice.void! }.should raise_error(Workflow::NoTransitionAllowed, "There is no event void defined for the draft state")
      end
    end

    context "issueing the invoice" do
      before(:each) do
        @invoice.issue!
      end

      it "should be marked as an issued invoice" do
        @invoice.should be_issued
      end

      it "should create a debit transaction with an amount matching the sum of its line item amounts" do
        @invoice.transactions.length.should == 1
        @invoice.transactions.first.debit?
        @invoice.transactions.first.amount.should == 28212
      end

    end

  end
  
end