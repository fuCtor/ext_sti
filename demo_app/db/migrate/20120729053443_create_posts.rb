class CreatePosts < ActiveRecord::Migration
  def change
    create_table :posts do |t|
      t.string :name
	    t.references :post_type
      t.timestamps
    end
  end
end
