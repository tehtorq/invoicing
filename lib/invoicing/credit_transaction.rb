module Invoicing
  class CreditTransaction < Transaction
    
    def debit?
      true
    end
  
  end
end