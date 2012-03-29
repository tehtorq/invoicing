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
  
  end
end