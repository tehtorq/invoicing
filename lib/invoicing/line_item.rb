module Invoicing
  class LineItem < ActiveRecord::Base
    belongs_to :invoice
    belongs_to :invoiceable, polymorphic: true
  end
end