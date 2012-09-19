module Invoicing
  class CreditNote < Invoice
    has_one :credit_note_invoice, dependent: :destroy
    has_one :invoice, through: :credit_note_invoice
    has_many :credit_note_credit_transactions, dependent: :destroy

    def record_transaction_against_invoice!
      raise RuntimeError, "You must allocate a credit note against an invoice." if invoice.blank?
      invoice.add_credit_transaction(amount: total)
      invoice.save!
      CreditNoteCreditTransaction.create!(transaction: invoice.transactions.last, credit_note_id: self.id)
    end

    def credit(options={})
      add_line_item(
        invoiceable: options[:line_item].invoiceable,
        amount: options[:amount] || 0,
        tax: options[:tax] || 0,
        description: options[:description] || "Credit note against #{options[:line_item].description}" #?
      )
    end

    def against_invoice(invoice)
      self.credit_note_invoice = CreditNoteInvoice.new(invoice_id: invoice.id)
    end

    def record_credit_notes!
      line_items.each do |line_item|
        invoiceable = line_item.invoiceable
        next if invoiceable.blank?
        invoiceable.handle_credit(line_item.amount) if invoiceable.respond_to?(:handle_credit)
        invoiceable.save!
      end
    end

    def annul(params={})
      record_amount_against_invoice(params[:amount], params[:against_invoice]) if params[:against_invoice]
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