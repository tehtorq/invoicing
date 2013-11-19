module Uomi
  class DebitTransaction < Transaction
    
    def debit?
      true
    end
  
  end
end