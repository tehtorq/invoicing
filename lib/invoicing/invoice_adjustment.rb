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

    def edit_line_item(item, params)
      raise CannotEditNonExistantLineItem if invoice.line_items.find(item.id).blank?
      self.invoice.line_items.for(item).update_attributes(params)
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

    def numbered(invoice_number)
      invoice.numbered(invoice_number)
    end

    def decorate_with(decorations)
      invoice.decorate_with(decorations)
    end

    def persist!
      # this method makes me a little sad.
      self.invoice.transaction do 
        self.invoice.invoice_decorator.save
        self.invoice.line_items.map(&:reload)
        self.invoice.save!
      end
    end
  end

end