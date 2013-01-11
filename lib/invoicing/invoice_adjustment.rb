module Invoicing

  class InvoiceAdjustment

    attr_accessor :invoice

    def initialize(invoice)
      raise CannotAdjustIssuedDocument unless invoice.draft?
      self.invoice = invoice
    end

    def due(due_date)
      invoice.due(due_date)
    end

    def add_line_item(params)
      invoice.line_item(params)
    end

    def remove_line_item(item)
      invoice.line_items.delete(item)
    end

    def add_payment_reference(payment_reference)
      invoice.payment_reference(payment_reference)
    end

    def remove_payment_reference(payment_reference)
      invoice.remove_payment_reference(payment_reference)
    end

    def to(buyerable)
      invoice.to(buyerable)
    end

    def decorate_with(decorations)
      invoice.decorate_with(decorations)
    end

    def persist!
      invoice.save!
    end
  end

end