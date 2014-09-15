require "active_record"
require "workflow"
require "uomi/version"

module Uomi
    
  def self.table_name_prefix
    'uomi_'
  end
  
  def self.generate_invoice(&block)
    ActiveRecord::Base.transaction do
      invoice = Invoice.new
      invoice.instance_eval(&block)
      invoice.save!
      invoice
    end
  end

  def self.generate_credit_note(&block)
    ActiveRecord::Base.transaction do
      credit_note = CreditNote.new
      credit_note.instance_eval(&block)
      credit_note.save!
      credit_note
    end
  end
  
end

require "uomi/exception"
require "uomi/invoiceable"
require "uomi/transaction"
require "uomi/credit_transaction"
require "uomi/debit_transaction"
require "uomi/late_payment"
require "uomi/line_item"
require "uomi/payment_reference"
require "uomi/seller"
require "uomi/buyer"
require "uomi/invoice_decorator"
require "uomi/credit_note_invoice"
require "uomi/credit_note_credit_transaction"

require "uomi/invoice"
require "uomi/credit_note"
require "uomi/overdue_invoice"
require "uomi/invoice_adjustment"
require "uomi/line_item_type"
