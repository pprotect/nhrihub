class CreateComplainant < ActiveRecord::Migration[6.0]
  def change
    create_table :complainants do |t|
      t.string "firstName"
      t.string "lastName"
      t.string "title"
      t.string "gender", limit: 1
      t.date "dob"
      t.string "occupation"
      t.string "employer"
      t.string "physical_address"
      t.string "postal_address"
      t.string "city"
      t.integer "province_id"
      t.string "postal_code"
      t.string "phone"
      t.string "email"
      t.string "cell_phone"
      t.string "home_phone"
      t.string "fax"
      t.integer "preferred_means", limit: 2
      t.integer "id_type", limit: 2, default: 0
      t.bigint "id_value"
      t.integer "alt_id_type", limit: 2
      t.string "alt_id_value"
      t.string "alt_id_other_type"
      t.timestamps
    end

    create_table :complaint_complainants do |t|
      t.integer "complaint_id"
      t.integer "complainant_id"
      t.timestamps
    end

    Complaint.all.each do |complaint|
      keys= ["firstName","lastName","title","gender","dob","occupation","employer",
             "physical_address","postal_address","city","province_id","postal_code",
             "phone","email","cell_phone","home_phone","fax","preferred_means",
             "id_type","id_value","alt_id_type","alt_id_value","alt_id_other_type"]
      attrs = complaint.attributes.slice(keys)
      complainant = Complainant.create(attrs)
      ComplaintComplainant.create(complaint_id: complaint.id, complainant_id: complainant.id)
    end

    remove_column :complaints, :firstName, :string
    remove_column :complaints, :lastName, :string
    remove_column :complaints, :title, :string
    remove_column :complaints, :gender, :string, limit: 1
    remove_column :complaints, :dob, :date
    remove_column :complaints, :occupation, :string
    remove_column :complaints, :employer, :string
    remove_column :complaints, :physical_address, :string
    remove_column :complaints, :postal_address, :string
    remove_column :complaints, :city, :string
    remove_column :complaints, :province_id, :integer
    remove_column :complaints, :postal_code, :string
    remove_column :complaints, :phone, :string
    remove_column :complaints, :email, :string
    remove_column :complaints, :cell_phone, :string
    remove_column :complaints, :home_phone, :string
    remove_column :complaints, :fax, :string
    remove_column :complaints, :preferred_means, :integer, limit: 2
    remove_column :complaints, :id_type, :integer, limit: 2, default: 0
    remove_column :complaints, :id_value, :bigint
    remove_column :complaints, :alt_id_type, :integer, limit: 2
    remove_column :complaints, :alt_id_value, :string
    remove_column :complaints, :alt_id_other_type, :string

  end
end
