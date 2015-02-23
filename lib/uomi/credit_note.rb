module Uomi
  class CreditNote < Invoice
    alias_attribute :receipt_number, :invoice_number

    has_many :credit_note_invoices, dependent: :destroy
    has_many :invoices, through: :credit_note_invoices
    has_many :credit_note_credit_transactions, dependent: :destroy

    workflow do
      state :draft do
        event :issue, transitions_to: :issued
        event :void, transitions_to: :voided
      end
      
      state :issued do
        event :settle, transitions_to: :settled
        event :void, transitions_to: :voided
      end

      state :settled do
        event :void, transitions_to: :voided
      end

      state :voided
    end

    def issue(issued_at = Time.now)
      self.issued_at = issued_at
      create_initial_transaction!
      record_transaction_against_invoice! unless self.invoices.blank?
      record_credit_notes!
      record_transaction!
    end

    def record_transaction_against_invoice!
      invoice = invoices.first
      validate(invoice: invoice, amount: self.total)
      invoice.add_credit_transaction(amount: total)
      invoice.save!
      CreditNoteCreditTransaction.create!(transaction: invoice.transactions.last, credit_note_id: self.id)
    end

    def credit(options={})
      add_line_item(
        invoiceable: options[:line_item].andand.invoiceable,
        amount: options[:amount] || 0,
        tax: options[:tax] || 0,
        description: options[:description] || "Credit note against #{options[:line_item].andand.description}" #?
      )
    end

    def against_invoice(invoice)
      raise RuntimeError, "You must allocate a credit note against an invoice" if invoice.blank?
      raise RuntimeError, "You must allocate a credit note against an issued invoice" unless invoice.issued?
      
      self.credit_note_invoices << CreditNoteInvoice.new(invoice_id: invoice.id)
      self.buyer = invoice.buyer
      self.seller = invoice.seller
    end

    def record_transaction!
      unless self.invoices.blank?
        add_debit_transaction(amount: total)
      end
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

    def validate(options={})
      raise RuntimeError, "You must allocate this credit against an invoice" if options[:invoice].blank?
      raise RuntimeError, "You must allocate this credit against a Uomi Invoice" unless options[:invoice].is_a?(Uomi::Invoice)
      raise RuntimeError, "You cannot allocate nothing to the invoice" if (options[:amount].blank? || options[:amount].zero?)
    end

    # Refund section

    def refund(&block)
      instance_eval(&block)
      save!
    end

    def set_balance_off(options={})
      validate(options)
      invoice = options[:invoice]

      invoice.add_credit_transaction(amount: options[:amount])
      against_invoice(invoice)
      invoice.save!

      self.add_debit_transaction(amount: options[:amount])
      CreditNoteCreditTransaction.create!(transaction: invoice.transactions.last, credit_note_id: self.id)
    end

    def void
      annul_remaining_amount! unless self.draft?
      reverse_transactions_against_invoice
      self
    end

    def reverse_transactions_against_invoice
      credit_note_credit_transactions.each do |cnct|
        invoice = cnct.transaction.invoice
        invoice.add_debit_transaction(amount: cnct.transaction.amount)
        invoice.save!
      end
    end
  end
end