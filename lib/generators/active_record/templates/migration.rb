class CreateUomiTables < ActiveRecord::Migration
  def self.change

    create_table "uomi_late_payments", :force => true do |t|
      t.integer  "invoice_id"
      t.integer "amount"
      t.datetime "penalty_date"
      t.boolean  "processed"
      t.timestamps
    end

    create_table "uomi_line_items", :force => true do |t|
      t.integer "invoice_id"
      t.string  "description"
      t.integer "amount"
      t.integer "tax"
      t.integer "invoiceable_id"
      t.string "invoiceable_type"
      t.integer "line_item_type_id"
      t.timestamps
    end

    add_index(:uomi_line_items, :invoice_id)

    create_table "uomi_transactions", :force => true do |t|
      t.integer "invoice_id"
      t.string  "type"
      t.integer "amount"
      t.timestamps
    end

    add_index(:uomi_transactions, :invoice_id)

    create_table "uomi_invoices", :force => true do |t|
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
    
    create_table "uomi_payment_references", :force => true do |t|
      t.integer "invoice_id"
      t.string "reference"
      t.timestamps
    end

    add_index(:uomi_payment_references, :invoice_id)
    
    create_table "uomi_sellers", :force => true do |t|
      t.integer "sellerable_id"
      t.string "sellerable_type"
      t.timestamps
    end

    create_table "uomi_buyers", :force => true do |t|
      t.integer "buyerable_id"
      t.string "buyerable_type"
      t.timestamps
    end
    
    create_table "uomi_invoice_decorators", :force => true do |t|
      t.integer "invoice_id"
      t.text "data"
      t.timestamps
    end

    add_index(:uomi_invoice_decorators, :invoice_id)

    create_table "uomi_credit_note_invoices", :force => true do |t|
      t.integer "invoice_id"
      t.integer "credit_note_id"
    end

    create_table "uomi_credit_note_credit_transactions", :force => true do |t|
      t.integer "credit_note_id"
      t.integer "transaction_id"
    end

    create_table "uomi_line_item_types", :force => true do |t|
      t.string "name"
    end
 
  end

end
