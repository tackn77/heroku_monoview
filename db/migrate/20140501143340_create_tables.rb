class CreateTables < ActiveRecord::Migration
  def change
    create_table :tables do |t|
      t.integer :month
      t.integer :day
      t.boolean :holiday
      t.integer :train
      t.integer :table

      t.timestamps
    end
  end
end
