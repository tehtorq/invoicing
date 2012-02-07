module Invoicing
  class LatePayment < ActiveRecord::Base
    belongs_to :invoice
  
    before_create :set_penalty_date
  
    def set_penalty_date
      self.penalty_date = Date.today + 7.days
    end
  end
end