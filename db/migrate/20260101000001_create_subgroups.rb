class CreateSubgroups < ActiveRecord::Migration[8.0]
  def change
    create_table :subgroups do |t|
      t.string     :name,        null: false
      t.references :group,       null: false, foreign_key: true
      t.references :created_by,  null: false, foreign_key: { to_table: :users }
      t.integer    :max_members, default: 5
      t.string     :description
      t.timestamps
    end

    create_table :subgroup_members do |t|
      t.references :subgroup, null: false, foreign_key: true
      t.references :user,     null: false, foreign_key: true
      t.integer    :role,     default: 0, null: false  # 0=member, 1=leader
      t.timestamps
    end

    add_index :subgroup_members, [:subgroup_id, :user_id], unique: true
  end
end
