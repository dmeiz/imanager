class CreateJoinTablePeopleProjects < ActiveRecord::Migration[7.1]
  def change
    create_join_table :people, :projects do |t|
      # t.index [:person_id, :project_id]
      # t.index [:project_id, :person_id]
    end
  end
end
