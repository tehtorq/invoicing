module Invoicing
  class Seller < ActiveRecord::Base
    has_many :invoices
    
    def self.generate_invoice(&block)
      invoice = Invoice.new
      invoice.instance_eval(&block)
      invoice.save!
      invoice.mark_items_invoiced!    
      invoice
    end
  end
end