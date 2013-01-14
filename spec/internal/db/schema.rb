ActiveRecord::Schema.define do
  
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
    t.integer "line_item_type_id"
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
    t.integer  "buyer_id"
    t.string   "invoice_number"
    t.datetime "due_date"
    t.datetime "issued_at"
    t.integer  "total"
    t.integer  "tax"
    t.integer  "balance"
    t.string   "type"
    t.string   "workflow_state"
    t.timestamps
  end
  
  create_table "invoicing_payment_references", :force => true do |t|
    t.integer "invoice_id"
    t.string "reference"
    t.timestamps
  end
  
  create_table "invoicing_sellers", :force => true do |t|
    t.integer "sellerable_id"
    t.string "sellerable_type"
    t.timestamps
  end

  create_table "invoicing_buyers", :force => true do |t|
    t.integer "buyerable_id"
    t.string "buyerable_type"
    t.timestamps
  end
  
  create_table "invoicing_invoice_decorators", :force => true do |t|
    t.integer "invoice_id"
    t.text "data"
    t.timestamps
  end

  create_table "invoicing_credit_note_invoices", :force => true do |t|
    t.integer "invoice_id"
    t.integer "credit_note_id"
  end

  create_table "invoicing_credit_note_credit_transactions", :force => true do |t|
    t.integer "credit_note_id"
    t.integer "transaction_id"
  end

  create_table "invoicing_line_item_types", :force => true do |t|
    t.string "name"
  end
  
end