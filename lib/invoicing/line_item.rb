module Invoicing
  class LineItem < ActiveRecord::Base
    belongs_to :invoice
    belongs_to :invoiceable, polymorphic: true
    belongs_to :line_item_type

    validates :amount, numericality: {greater_than_or_equal_to: 0}, presence: true
  
    def net_amount
      amount - tax
    end

    def self.for(item)
      where(id: item.id).first
    end
  end
end