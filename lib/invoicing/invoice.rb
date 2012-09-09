module Invoicing
  class Invoice < ActiveRecord::Base
    has_many :line_items, dependent: :destroy
    has_many :transactions, dependent: :destroy
    has_many :payment_references, dependent: :destroy
    has_one :late_payment, dependent: :destroy
    belongs_to :seller
    has_one :invoice_decorator, dependent: :destroy

    validates_uniqueness_of :invoice_number, scope: [:seller_id]
  
    before_save :calculate_totals, :calculate_balance
    after_create :create_initial_transaction!, :set_invoice_number!
    
    alias :decorator :invoice_decorator
    
    def add_line_item(params)
      self.line_items << LineItem.new(params)
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
      
    def create_initial_transaction!
      if total < 0
        add_credit_transaction amount: total
      else
        add_debit_transaction amount: total
      end

      save!
    end
    
    def set_invoice_number!
      self.invoice_number ||= "INV#{id}"
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
      self.balance = (0 - debit_transactions.sum(&:amount)) + credit_transactions.sum(&:amount)
    end
    
    def net_total
      total - tax
    end
      
    def settled?
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
    
    def add_payment_reference(params)
      self.payment_references << PaymentReference.new(params)
    end
    
    def self.for_payment_reference(reference)
      PaymentReference.where(reference: reference).map(&:invoice)
    end
    
    def mark_items_invoiced!
      line_items.map(&:invoiceable).compact.each do |item|
        item.invoiced = true
        item.invoice_id = id
        item.save!
      end
    end
    
    def line_item(cost_item)
      if cost_item.is_a? Hash
        add_line_item(
          amount: cost_item[:amount] || 0,
          tax: cost_item[:tax] || 0,
          description: cost_item[:description] || 'Line Item'
        )
      else
        add_line_item(
          invoiceable: cost_item,
          amount: cost_item.amount || 0,
          tax: cost_item.tax || 0,
          description: cost_item.description || 'Line Item'
        )
      end
    end
    
    def payment_reference(reference)
      add_payment_reference(reference: reference)
    end
    
    def due(due_date)
      self.due_date = due_date
    end
    
    def from(seller)
      self.seller = seller
    end
    
    def decorate_with(decorations)
      self.invoice_decorator = InvoiceDecorator.new data: decorations
    end

    def numbered(invoice_number)
      self.invoice_number = invoice_number
    end
  
  end
end