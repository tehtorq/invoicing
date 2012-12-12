require 'spec_helper'

describe Invoicing::CreditNote do
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

    @invoice.issue!
  end

  context "when recording a credit note" do
    before(:each) do
      @invoice.line_items.each do |li|
        li.invoiceable = li
        li.invoiceable.extend(Invoicing::Invoiceable)
        li.save!
      end

      @invoice.reload
    end

    it "should raise an exception if the invoice is not in an issued state" do
      lambda {
        @credit_note = Invoicing::generate_credit_note do
          against_invoice @invoice
        end
      }.should raise_error(RuntimeError, "You must allocate a credit note against an invoice")
      
    end

    context "against an invoice" do
      before(:each) do
        invoice = @invoice
        line_items = invoice.line_items

        @credit_note = Invoicing::generate_credit_note do
          line_items.each do |line_item|
            credit amount: line_item.amount, line_item: line_item, description: "Credit note for Line Item #{line_item.id}", tax: 0
          end

          against_invoice invoice
        end

        @invoice.reload
      end

      it "should be issued" do
        @credit_note.should be_issued
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

    end

    context "When applying credits to the invoiceables" do

      it "should receive handle credit for each line item being credited" do
        credit_note = Invoicing::CreditNote.new
        credit_note.line_items = @invoice.line_items

        credit_note.line_items.map(&:invoiceable).compact.each do |item|
          item.should_receive(:handle_credit)
        end

        credit_note.record_credit_notes!
      end

    end

    context "trying to create a standalone credit note" do

      it "should raise an error if no invoice is specified" do
        expect {Invoicing::generate_credit_note do
          line_items.each do |line_item|
            credit amount: 500, description: "Credit note for Line Item #{line_item.id}", tax: 0
          end
          decorate_with tenant_name: "Peter"
        end}.to raise_error(RuntimeError, "You must allocate a credit note against an invoice")
      end
    end

  end
  
end