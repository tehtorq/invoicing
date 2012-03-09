ActiveRecord::Schema.define do
  
  create_table "invoicing_late_payments", :force => true do |t|
    t.integer  "invoice_id"
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "penalty_date"
    t.boolean  "processed"
    t.timestamps
  end
  
  create_table "invoicing_line_items", :force => true do |t|
    t.integer "invoice_id"
    t.string  "description"
    t.decimal "amount", precision: 10, scale: 2
    t.integer "invoiceable_id"
    t.string "invoiceable_type"
    t.timestamps
  end
  
  create_table "invoicing_transactions", :force => true do |t|
    t.integer "invoice_id"
    t.string  "type"
    t.decimal "amount", precision: 10, scale: 2
    t.timestamps
  end
  
  create_table "invoicing_invoices", :force => true do |t|
    t.string   "invoice_number"
    t.datetime "due_date"
    t.decimal  "total", precision: 10, scale: 2
    t.decimal  "vat_amount", precision: 10, scale: 2
    t.decimal  "balance", precision: 10, scale: 2
    t.timestamps
  end
  
  create_table "invoicing_payment_references", :force => true do |t|
    t.integer "invoice_id"
    t.string "reference"
    t.timestamps
  end
  
end