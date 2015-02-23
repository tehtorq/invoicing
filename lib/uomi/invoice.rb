module Uomi
  class Invoice < ActiveRecord::Base
    include ::Workflow
    has_many :line_items, dependent: :destroy
    has_many :transactions, dependent: :destroy
    has_many :payment_references, dependent: :destroy
    has_one :late_payment, dependent: :destroy
    belongs_to :seller
    belongs_to :buyer
    has_one :invoice_decorator, dependent: :destroy

    validates_uniqueness_of :invoice_number, scope: [:seller_id]
  
    before_save :calculate_totals, :calculate_balance
    after_create :set_invoice_number!
    
    alias :decorator :invoice_decorator

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
        event :unsettle, transitions_to: :issued
      end

      state :voided
    end

    def issue(&block)
      self.issued_at = Time.now
      instance_eval(&block) if block_given?
      create_initial_transaction!
      mark_items_invoiced!
      self
    end
    
    def void
      raise CannotVoidDocumentException, "Cannot void a document that has a transaction recorded against it!" if transactions.many?
      annul_remaining_amount! unless self.draft?
      mark_items_uninvoiced!
      self
    end
    
    def add_line_item(params)
      self.line_items << LineItem.new(params)
    end

    def remove_line_item(item)
      line_items.delete(item)
    end
    
    def add_debit_transaction(params)
      self.transactions << DebitTransaction.new(params)
    end
    
    def add_credit_transaction(params)
      self.transactions << CreditTransaction.new(params)
    end
    
    def calculate_totals
      self.total = line_items.inject(0) {|res, item| res + item.amount.to_i}
      self.tax = line_items.inject(0) {|res, item| res + item.tax.to_i}
    end

    def annul_remaining_amount!
      add_credit_transaction amount: balance.abs
    end
      
    def create_initial_transaction!
      if total < 0
        add_credit_transaction amount: total
      else
        add_debit_transaction amount: total
      end
    end

    def credit_notes
      CreditNoteInvoice.where(invoice_id: id).map(&:credit_note)
    end

    def default_numbering_prefix
      "INV"
    end
    
    def set_invoice_number!
      self.invoice_number ||= "#{default_numbering_prefix}#{id}"
      self.invoice_number.gsub!("{id}", "#{id}")
      save!
    end
      
    def debit_transactions
      transactions.select{|t| t.is_a? DebitTransaction}
    end
      
    def credit_transactions
      transactions.select{|t| t.is_a? CreditTransaction}
    end
      
    def calculate_balance
      bal = (0 - debit_transactions.sum(&:amount)) + credit_transactions.sum(&:amount)
      self.balance = bal
      settle! if should_settle?
      unsettle! if (bal < 0 && settled?)
    end

    def should_settle?
      issued? && balance_zero?
    end
    
    def net_total
      total - tax
    end

    def balance_zero?
      balance == 0
    end
      
    def owing?
      balance < 0
    end
      
    def due_date_past?
      due_date.to_date < Date.today
    end
      
    def overdue?
      owing? and due_date_past?
    end
    
    def self.owing
      where("balance < ?", 0)
    end

    def self.issued
      where(workflow_state: "issued")
    end

    def self.draft
      where(workflow_state: "draft")
    end

    def self.settled
      where(workflow_state: "settled")
    end

    def self.voided
      where(workflow_state: "voided")
    end
    
    def add_payment_reference(params)
      self.payment_references << PaymentReference.new(params)
    end

    def remove_payment_reference(payment_reference)
      payment_references.delete(payment_reference)
    end
    
    def self.for_payment_reference(reference)
      PaymentReference.where(reference: reference).map(&:invoice)
    end
    
    def mark_items_invoiced!
      line_items.map(&:invoiceable).compact.each do |item|
        item.mark_invoiced(self) if item.respond_to?(:mark_invoiced)
      end
    end

    def mark_items_uninvoiced!
      line_items.map(&:invoiceable).compact.each do |item|
        item.mark_uninvoiced(self) if item.respond_to?(:mark_uninvoiced)
      end
    end
    
    def line_item(cost_item)
      if cost_item.is_a? Hash
        add_line_item(
          amount: cost_item[:amount] || 0,
          tax: cost_item[:tax] || 0,
          description: cost_item[:description] || 'Line Item',
          line_item_type_id: cost_item[:line_item_type_id]
        )
      else
        add_line_item(
          invoiceable: cost_item,
          amount: cost_item.amount || 0,
          tax: cost_item.tax || 0,
          description: cost_item.description || 'Line Item',
          line_item_type_id: cost_item.respond_to?(:line_item_type_id) ? cost_item.line_item_type_id : 0
        )
      end
    end
    
    def payment_reference(reference)
      add_payment_reference(reference: reference)
    end
    
    def due(due_date)
      self.due_date = due_date
    end

    def to(buyerable)
      self.buyer = Buyer.for(buyerable)
    end
    
    def from(sellerable)
      self.seller = Seller.for(sellerable)
    end
    
    def decorate_with(decorations)
      if self.invoice_decorator
        self.invoice_decorator.data = decorations
      else
        self.invoice_decorator = InvoiceDecorator.new(data: decorations)
      end
    end

    def numbered(invoice_number)
      self.invoice_number = invoice_number
    end

    def adjust(&block)
      adjustment = InvoiceAdjustment.new(self)
      adjustment.instance_eval(&block)
      adjustment.persist!
      adjustment.invoice
    end
  
  end

end