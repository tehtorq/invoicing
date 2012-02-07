class CreateInvoicingTables < ActiveRecord::Migration
  def self.change

    create_table "invoicing_late_payments", :force => true do |t|
      t.integer  "invoice_id"
      t.datetime "penalty_date"
      t.boolean  "processed"
      t.datetime "created_at",   :null => false
      t.datetime "updated_at",   :null => false
    end

    create_table "invoicing_line_items", :force => true do |t|
      t.integer "invoice_id"
      t.string  "description"
      t.float   "amount"
    end

    create_table "invoicing_transactions", :force => true do |t|
      t.integer "invoice_id"
      t.string  "type"
      t.float   "amount"
    end

    create_table "invoicing_invoices", :force => true do |t|
      t.string   "invoice_number"
      t.datetime "due_date"
      t.float    "total"
      t.float    "vat_amount"
      t.datetime "created_at",     :null => false
      t.datetime "updated_at",     :null => false
      t.float    "balance"
    end
 
  end

end