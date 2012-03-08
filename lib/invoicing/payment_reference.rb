module Invoicing
  
  class PaymentReference < ActiveRecord::Base
    
    belongs_to :invoice
    
    
  end
  
end