class CreateTestCasesAndResults < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_test_cases do |t|
      t.references :assignment, null: false, foreign_key: true
      t.string     :name,              null: false
      t.json       :inputs,            null: false   # { "A": 1, "B": 0 }
      t.json       :expected_outputs,  null: false   # { "Y": 1 }
      t.integer    :points,            default: 1
      t.integer    :position,          default: 0
      t.boolean    :sequential,        default: false  # needs more sim cycles
      t.timestamps
    end

    create_table :verification_results do |t|
      t.references :project,              null: false, foreign_key: true
      t.references :assignment_test_case, null: false, foreign_key: true
      t.boolean    :passed,    default: false
      t.json       :actual_outputs
      t.string     :status,    default: "pending"  # pending/passed/failed/unstable
      t.datetime   :verified_at
      t.timestamps
    end

    add_index :verification_results,
              [:project_id, :assignment_test_case_id],
              unique: true,
              name: "idx_verification_uniqueness"
  end
end
