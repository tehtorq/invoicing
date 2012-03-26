require "active_record"
require "invoicing/version"

module Invoicing
    
  def self.table_name_prefix
    'invoicing_'
  end
  
  #CONFIG_DIR = File.expand_path(File.dirname(__FILE__)) + "/config"
  
  def self.invoice(&block)
    #b = block
    
    #Invoice.transaction do
      invoice = Invoice.new
      invoice.instance_eval(&block)
      invoice.save!
      
      invoice.line_items.map(&:invoiceable).compact.each do |item|
        item.invoiced = true
        item.invoice_id = invoice.id
        item.save!
      end
    #end
    
    invoice
  end
  
end

require "invoicing/invoiceable"
require "invoicing/transaction"
require "invoicing/credit_transaction"
require "invoicing/debit_transaction"
require "invoicing/late_payment"
require "invoicing/line_item"
require "invoicing/payment_reference"

require "invoicing/invoice"
require "invoicing/overdue_invoice"
