require "active_record"
require "workflow"
require "invoicing/version"

module Invoicing
    
  def self.table_name_prefix
    'invoicing_'
  end
  
  def self.generate(&block)
    invoice = Invoice.new
    invoice.instance_eval(&block)
    invoice.save!
    #invoice.mark_items_invoiced!    
    invoice
  end

  def self.generate_credit_note(&block)
    credit_note = CreditNote.new
    credit_note.instance_eval(&block)
    credit_note.save!
    credit_note.record_transaction_against_invoice!
    credit_note.record_credit_notes!
    credit_note
  end
  
end

require "invoicing/invoiceable"
require "invoicing/transaction"
require "invoicing/credit_transaction"
require "invoicing/debit_transaction"
require "invoicing/late_payment"
require "invoicing/line_item"
require "invoicing/payment_reference"
require "invoicing/seller"
require "invoicing/invoice_decorator"
require "invoicing/credit_note_invoice"
require "invoicing/credit_note_credit_transaction"

require "invoicing/invoice"
require "invoicing/credit_note"
require "invoicing/overdue_invoice"
