module Invoicing
  class LineItemType < ActiveRecord::Base
    has_many :line_items

  end
end