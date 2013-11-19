# implement this module and override behaviour on items which will be invoiced

module Uomi
  module Invoiceable
  
    attr_accessor :invoiced, :invoice_id, :amount, :tax, :line_item_type_id

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