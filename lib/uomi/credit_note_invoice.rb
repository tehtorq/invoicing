module Uomi
  class CreditNoteInvoice < ActiveRecord::Base
    belongs_to :credit_note
    belongs_to :invoice
  end
end