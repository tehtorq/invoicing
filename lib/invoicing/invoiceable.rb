# implement this module and override behaviour on items which will be invoiced

module Invoicing
  module Invoiceable
  
    attr_accessor :invoiced, :invoice_id, :amount, :tax

    def description
      "Invoiceable Item"
    end

    def handle_credit(amount)
    end

    def mark_invoiced(invoice)
    end

    def mark_uninvoiced
    end
  
  end
end