module Invoicing
  class CreditNote < Invoice
    has_many :credit_note_invoices, dependent: :destroy
    has_many :credit_note_credit_transactions, dependent: :destroy

    def record_amount_against_invoice(amount, invoice)
      self.credit_note_invoices << CreditNoteInvoice.new(invoice_id: invoice.id)
      invoice.add_credit_transaction(amount: amount)
      invoice.save #update invoice balance

      self.credit_note_credit_transactions << CreditNoteCreditTransaction.new(transaction: invoice.transactions.last)
    end

    def against_invoices(invoices)
      invoices.each do |invoice|
        against_invoice(invoice)
      end
    end

    def line_item(cost_item)
      super(cost_item)
      if cost_item[:against_invoice]
        record_amount_against_invoice(self.line_items.last.amount, cost_item[:against_invoice])
      end
    end

    def set_invoice_number!
      self.invoice_number ||= "CN#{id}"
      self.invoice_number.gsub!("{id}", "#{id}")
      save!
    end

    def receipt_number
      self.invoice_number
    end

    def create_initial_transaction!
      if total > 0
        add_credit_transaction amount: total
      else
        add_debit_transaction amount: total
      end

      save!
    end
  end
end