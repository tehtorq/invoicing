require 'spec_helper'

describe Uomi::CreditNote do
  
  before(:each) do
    invoice_buyer = Uomi::DebitTransaction.create!
    invoice_seller = Uomi::DebitTransaction.create!
    
    @invoice = Uomi::generate_invoice do
      to invoice_buyer
      from invoice_seller

      line_item description: "Line Item 1", amount: 1101
      line_item description: "Line Item 2", amount: 5097
      line_item description: "Line Item 3", amount: 1714
      line_item description: "Line Item 4", amount: 20300

      payment_reference "REF123"
      decorate_with tenant_name: "Peter"
    end

    @invoice_buyer = invoice_buyer
    @invoice_seller = invoice_seller

    @invoice.issue!
  end

  context "when recording a credit note" do
    before(:each) do
      @invoice.line_items.each do |li|
        li.invoiceable = li
        li.invoiceable.extend(Uomi::Invoiceable)
        li.amount = 0
        li.tax = 0
        li.save!
      end

      @invoice.reload
    end

    it "should raise an exception if the invoice is not in an issued state" do
      lambda {
        @credit_note = Uomi::generate_credit_note do
          against_invoice @invoice
        end
      }.should raise_error(RuntimeError, "You must allocate a credit note against an invoice")
      
    end

    context "against an invoice" do
      before(:each) do
        invoice = @invoice
        line_items = invoice.line_items

        @credit_note = Uomi::generate_credit_note do
          line_items.each do |line_item|
            credit amount: line_item.amount, line_item: line_item, description: "Credit note for Line Item #{line_item.id}", tax: 0
          end

          against_invoice invoice
        end

        @credit_note.issue!

        @invoice.reload
      end

      it "should have a receipt number" do
        @credit_note.receipt_number.should == "CN#{@credit_note.id}"
      end

      it "should be able to record a line item for the credit note" do
        @credit_note.line_items.count.should == @invoice.line_items.count
        @credit_note.line_items.first.amount.should == @invoice.line_items.first.amount
      end

      it "should create a credit transaction against the invoice" do
        @invoice.settled?.should be_true
      end

      it "should know if it is linked to an invoice" do
        @credit_note.invoice.should == @invoice
      end

      it "should be linked to the credit transaction paid against the invoice" do
        @credit_note.credit_note_credit_transactions.count.should == 1
        @credit_note.credit_note_credit_transactions.first.transaction.amount.should == @invoice.total
      end

      it "should be recorded against the invoice" do
        @invoice.reload
        @invoice.credit_notes.count.should == 1
        @invoice.credit_notes.first.receipt_number.should == "CN#{@credit_note.id}"
      end

      it "should set the buyer to the invoice's buyer" do
        @credit_note.buyer.buyerable.should == @invoice_buyer
      end

      it "should set the seller to the invoice's seller" do
        @credit_note.seller.sellerable.should == @invoice_seller
      end

      it "should set the balance to 0 if applied against an invoice" do
        @credit_note.balance.should == 0
      end

      it "should mark the credit note as settled" do
        @credit_note.should be_settled
      end

    end

    context "Ad Hoc Credit Note not applied to any invoices" do
      before(:each) do
        @credit_note = Uomi::generate_credit_note do
          credit amount: 5000, description: 'Description'
          credit amount: 2000, description: 'Another Description'
        end
        @credit_note.issue!
      end

      it "should generate a credit note to the value of 70.00" do
        @credit_note.total.should == 7000
      end

      it "should have a balance of 70.00" do
        @credit_note.balance.should == 7000
      end

      context "Applying credit note to multiple invoices" do
        before(:each) do
          @invoice1 = Uomi::generate_invoice do
            line_item description: "Line Item 1", amount: 5000, line_item_type_id: 1
          end
          @invoice1.issue!

          @invoice2 = Uomi::generate_invoice do
            line_item description: "Line Item 1", amount: 2000, line_item_type_id: 1
          end
          @invoice2.issue!
        end

        context "Apply R50 credit to invoice 1" do
          before(:each) do
            inv = @invoice1

            @credit_note.refund do
              set_balance_off invoice: inv, amount: 5000
            end

            @credit_note.reload
            @invoice1.reload
          end

          it "should settle the invoice" do
            @invoice1.should be_settled
          end

          it "should set the balance on the credit note to 20" do
            @credit_note.balance.should == 2000
          end

          it "should have created a debit transaction on the credit note to the value of 50.00" do
            @credit_note.debit_transactions.last.amount.should == 5000
          end

          it "should have created a credit transaction against the invoice for 50.00" do
            @invoice1.credit_transactions.last.amount.should == 5000
          end

          it "should know which invoice the credit note has transacted against" do
            t = @credit_note.credit_note_credit_transactions.last
            t.transaction.invoice.should == @invoice1
          end
        end
      end
    end

    context "When applying credits to the invoiceables" do

      it "should receive handle credit for each line item being credited" do
        credit_note = Uomi::CreditNote.new
        credit_note.line_items = @invoice.line_items

        credit_note.line_items.map(&:invoiceable).compact.each do |item|
          item.should_receive(:handle_credit)
        end

        credit_note.record_credit_notes!
      end

    end
  end
  
end