module Invoicing
  class DebitTransaction < Transaction
    
    def debit?
      true
    end
  
  end
end