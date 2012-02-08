module Invoicing
  class CreditTransaction < Transaction
    
    def credit?
      true
    end
  
  end
end