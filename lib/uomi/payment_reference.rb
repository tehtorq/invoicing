module Uomi
  
  class PaymentReference < ActiveRecord::Base
    
    belongs_to :invoice
    
    
  end
  
end