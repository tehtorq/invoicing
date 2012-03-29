module Invoicing
  class LineItem < ActiveRecord::Base
    belongs_to :invoice
    belongs_to :invoiceable, polymorphic: true
    
    def net_amount
      amount - tax
    end
  end
end