module Invoicing
  class Transaction < ActiveRecord::Base
    belongs_to :invoice
  end
end