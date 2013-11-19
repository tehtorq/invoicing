module Uomi
  class CreditNote < Invoice
    alias_attribute :receipt_number, :invoice_number

    has_one :credit_note_invoice, dependent: :destroy
    has_one :invoice, through: :credit_note_invoice
    has_many :credit_note_credit_transactions, dependent: :destroy

    def issue(issued_at = Time.now)
      self.issued_at = issued_at
      create_initial_transaction!
      record_transaction_against_invoice!
      record_credit_notes!
    end

    def record_transaction_against_invoice!
      raise RuntimeError, "You must allocate a credit note against an invoice" if invoice.blank?
      raise RuntimeError, "You must allocate a credit note against an issued invoice" unless invoice.issued?

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
      raise RuntimeError, "You must allocate a credit note against an invoice" if invoice.blank?
      raise RuntimeError, "You must allocate a credit note against an issued invoice" unless invoice.issued?
      
      self.credit_note_invoice = CreditNoteInvoice.new(invoice_id: invoice.id)
      self.buyer = invoice.buyer
      self.seller = invoice.seller
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

    def default_numbering_prefix
      "CN"
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