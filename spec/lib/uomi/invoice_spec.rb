require 'spec_helper'

describe Uomi::Invoice do
  
  before(:each) do
    @invoice = Uomi::generate_invoice do
      line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      line_item description: "Line Item 2", amount: 5097, line_item_type_id: 1
      line_item description: "Line Item 3", amount: 1714, line_item_type_id: 1
      line_item description: "Line Item 4", amount: 20300, line_item_type_id: 1

      payment_reference "REF123"
      decorate_with tenant_name: "Peter"
    end
  end
  
  it "should be able to add a line item" do
    invoice = Uomi::generate_invoice do
      line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
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

    it "should record the issued time" do
      @invoice.issued_at.to_date.should == Date.today
    end

  end

  context "searching for sets of invoices" do

    it "should find draft invoices" do
      issued_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end

      issued_invoice.issue!

      draft_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1, line_item_type_id: 1
      end
      
      Uomi::Invoice.draft.count.should == 2
      Uomi::Invoice.draft.last.should == draft_invoice
    end

    it "should find issued invoices" do
      issued_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end

      issued_invoice.issue!

      other_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end
      
      Uomi::Invoice.issued.count.should == 1
      Uomi::Invoice.issued.first.should == issued_invoice
    end

    it "should find owing invoices" do
      owing_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end

      owing_invoice.issue!

      other_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end
      
      Uomi::Invoice.owing.count.should == 1
      Uomi::Invoice.owing.first.should == owing_invoice
    end

    it "should find settled invoices" do
      settled_invoice = Uomi::generate_invoice do
      end

      settled_invoice.issue!

      other_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end
      
      Uomi::Invoice.settled.count.should == 1
      Uomi::Invoice.settled.first.should == settled_invoice
    end

    it "should find voided invoices" do
      voided_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end

      voided_invoice.issue!
      voided_invoice.void!

      other_invoice = Uomi::generate_invoice do
        line_item description: "Line Item 1", amount: 1101, line_item_type_id: 1
      end
      
      Uomi::Invoice.voided.count.should == 1
      Uomi::Invoice.voided.first.should == voided_invoice
    end

  end

  context "specifying an invoice number" do
  
    it "should default the invoice number to a format of INV{invoice id}" do
      @invoice.invoice_number.should == "INV#{@invoice.id}"
    end

    it "should allow a specific invoice number to be specified" do
      invoice = Uomi::generate_invoice do
        numbered "CUSTOMREF123"
      end
      
      invoice.invoice_number.should == "CUSTOMREF123"
    end

    it "should allow a custom invoice number format to be specified containing the invoice id" do
      invoice = Uomi::generate_invoice do
        numbered "CUSTOMREF{id}"
      end

      invoice.invoice_number.should == "CUSTOMREF#{invoice.id}"
    end

    it "should validate that the invoice number is unique per seller" do
      seller = Uomi::DebitTransaction.create!

      invoice = Uomi::generate_invoice do
        numbered "CUSTOMREF123"
        from seller
      end

      expect {
        invoice = Uomi::generate_invoice do
          numbered "CUSTOMREF123"
          from seller
        end
      }.to raise_error(ActiveRecord::RecordInvalid, "Validation failed: Invoice number has already been taken")
    end

    it "should allow two invoices with the same invoice number, but from different sellers" do
      first_seller = Uomi::DebitTransaction.create!

      invoice = Uomi::generate_invoice do
        numbered "CUSTOMREF123"
        from first_seller
      end

      second_seller = Uomi::DebitTransaction.create!

      expect {
        invoice = Uomi::generate_invoice do
          numbered "CUSTOMREF123"
          from second_seller
        end
      }.to_not raise_error
    end

  end
  
  it "should be able to register multiple payment references to look up invoices by" do
    invoice = Uomi::generate_invoice do
      payment_reference "Mr. Anderson"
      payment_reference "REF23934"
    end
    
    invoice.payment_references.map(&:reference).should == ["Mr. Anderson", "REF23934"]
  end
  
  it "should be able to specify the seller" do
    seller = Uomi::DebitTransaction.create!
    
    invoice = Uomi::generate_invoice do
      from seller
    end
    
    invoice.seller.sellerable.should == seller
  end
  
  it "should be able to find invoices for a given reference" do
    invoice1 = Uomi::generate_invoice do
      payment_reference "Mr. Anderson"
      payment_reference "REF23934"
    end
    
    invoice2 = Uomi::generate_invoice do
      payment_reference "Mr. Anderson"
    end
    
    Uomi::Invoice.for_payment_reference("Mr. Anderson").should == [invoice1, invoice2]
    Uomi::Invoice.for_payment_reference("REF23934").should == [invoice1]
    Uomi::Invoice.for_payment_reference("My Payment").should == []
  end
  
  context "when adding a line item" do
    
    it "should be able to attach an invoiceable item to the line item" do
      item_to_invoice = @invoice.extend(Uomi::Invoiceable)
      
      invoice = Uomi::generate_invoice do
        line_item item_to_invoice
      end
      
      invoice.line_items.first.invoiceable.should == @invoice
    end
  end
  
  it "should be able to add decoration data to the invoice" do
    item_to_invoice = @invoice.extend(Uomi::Invoiceable)

    decoration = {invoicee: "Bob Jones"}
    
    invoice = Uomi::generate_invoice do
      line_item item_to_invoice
      decorate_with decoration
    end
    
    invoice.decorator.data.should == {invoicee: "Bob Jones"}
  end

  context "destroying an invoice" do

    it "should destroy its associated line items" do
      Uomi::LineItem.create! amount: 0
      Uomi::LineItem.count.should == 5
      @invoice.destroy
      Uomi::LineItem.count.should == 1
    end

    it "should destroy its associated transactions" do
      @invoice.issue!
      Uomi::Transaction.create!
      Uomi::Transaction.count.should == 2
      @invoice.destroy
      Uomi::Transaction.count.should == 1
    end

    it "should destroy its associated payment_references" do
      Uomi::PaymentReference.create!
      Uomi::PaymentReference.count.should == 2
      @invoice.destroy
      Uomi::PaymentReference.count.should == 1
    end

    it "should destroy its associated late payments" do
      Uomi::LatePayment.create!
      Uomi::LatePayment.create! invoice_id: @invoice.id
      Uomi::LatePayment.count.should == 2
      @invoice.destroy
      Uomi::LatePayment.count.should == 1
    end

    it "should destroy its associated decorator" do
      Uomi::InvoiceDecorator.create!
      Uomi::InvoiceDecorator.count.should == 2
      @invoice.destroy
      Uomi::InvoiceDecorator.count.should == 1
    end

  end

  context "giving the invoice state" do

    context "new invoice" do
      it "should default to the state draft" do
        @invoice.should be_draft
      end

      context "voiding a drafted invoice" do
        before(:each) do
          @invoice.void!
        end

        it "should be marked as a voided invoice" do
          @invoice.should be_voided
        end

        it "should not create a credit transaction against the draft invoice" do
          @invoice.transactions.should be_blank
        end
      end
    end

    context "issuing the invoice" do
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

      context "voiding an issued invoice" do
        before(:each) do
          @invoice.void!
        end

        it "should mark the invoice as voided" do
          @invoice.should be_voided
        end

        it "should create a credit transaction against the invoice" do
          @invoice.credit_transactions.count.should == 1
        end

        it "should set the balance on the invoice to zero" do
          @invoice.balance.should == 0
        end

      end

      context "voiding an issued invoice with a payment recorded against it" do
        before(:each) do
          @invoice.add_credit_transaction amount: 1
        end

        it "should raise an error when voiding the invoice" do
          lambda { @invoice.void! }.should raise_error(Uomi::CannotVoidDocumentException, "Cannot void a document that has a transaction recorded against it!")
        end
      end
    end
  end

  context "Hooks" do
    before(:each) do
      item_to_invoice = @invoice.extend(Uomi::Invoiceable)
      item_to_invoice.amount = 10
        
      @invoice2 = Uomi::generate_invoice do
        line_item item_to_invoice
      end

      @item_to_invoice = item_to_invoice
    end

    context "issuing the invoice" do
      it "the items to invoice should receive a mark invoice call" do
        @item_to_invoice.should_receive(:mark_invoiced).with(@invoice2)
        @invoice2.issue!
      end
    end

    context "voiding the issued invoice" do
      before(:each) do
        @invoice2.issue!
      end

      it "the items to invoice should receive a mark uninvoiced call" do
        @item_to_invoice.should_receive(:mark_uninvoiced).with(@invoice2)
        @invoice2.void!
      end

    end
  end

end