class CreateInvoicingTables < ActiveRecord::Migration
  def self.change

    create_table "invoicing_late_payments", :force => true do |t|
      t.integer  "invoice_id"
      t.integer "amount"
      t.datetime "penalty_date"
      t.boolean  "processed"
      t.timestamps
    end

    create_table "invoicing_line_items", :force => true do |t|
      t.integer "invoice_id"
      t.string  "description"
      t.integer "amount"
      t.integer "tax"
      t.integer "invoiceable_id"
      t.string "invoiceable_type"
      t.timestamps
    end

    create_table "invoicing_transactions", :force => true do |t|
      t.integer "invoice_id"
      t.string  "type"
      t.integer "amount"
      t.timestamps
    end

    create_table "invoicing_invoices", :force => true do |t|
      t.integer  "seller_id"
      t.string   "invoice_number"
      t.datetime "due_date"
      t.integer  "total"
      t.integer  "tax"
      t.integer  "balance"
      t.timestamps
    end
    
    create_table "invoicing_payment_references", :force => true do |t|
      t.integer "invoice_id"
      t.string "reference"
      t.timestamps
    end
    
    create_table "invoicing_sellers", :force => true do |t|
      t.timestamps
    end
 
  end

end