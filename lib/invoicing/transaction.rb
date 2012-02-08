module Invoicing
  class Transaction < ActiveRecord::Base
    belongs_to :invoice
    
    def debit?
      false
    end
    
    def credit?
      false
    end
  end
end