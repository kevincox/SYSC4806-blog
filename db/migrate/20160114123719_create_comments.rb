class CreateComments < ActiveRecord::Migration
  def change
    create_table :comments do |t|
      t.text :commentext
      t.string :author
      t.integer :blogpost_id

      t.timestamps null: false
    end
  end
end
