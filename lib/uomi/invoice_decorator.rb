module Uomi
  class InvoiceDecorator < ActiveRecord::Base
    belongs_to :invoice
    serialize :data
  end
end