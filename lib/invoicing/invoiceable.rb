module Invoicing
  module Invoiceable
  
    attr_accessor :invoiced, :invoice_id

    def amount
      0
    end
  
    def tax
      0
    end
  
    def description
      "Invoiceable Item"
    end

    def handle_credit(amount)
      self.amount = amount
    end

    def mark_invoiced(invoice_id)
      self.invoice_id = invoice_id
      self.invoiced = true
    end
  
  end
end