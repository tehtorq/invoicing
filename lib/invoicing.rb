require "active_record"
require "invoicing/version"

module Invoicing
    
  def self.table_name_prefix
    'invoicing_'
  end
  
  #CONFIG_DIR = File.expand_path(File.dirname(__FILE__)) + "/config"
  
end

require "invoicing/transaction"
require "invoicing/credit_transaction"
require "invoicing/debit_transaction"
require "invoicing/late_payment"
require "invoicing/line_item"

require "invoicing/invoice"
