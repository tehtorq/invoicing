module Uomi
  class CreditNoteCreditTransaction < ActiveRecord::Base
    belongs_to :credit_note
    belongs_to :transaction
  end
end