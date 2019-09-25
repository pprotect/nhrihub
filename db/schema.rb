# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_09_19_154052) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "access_events", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.string "exception_type"
    t.string "login"
    t.string "request_ip"
    t.string "request_user_agent"
  end

  create_table "action_role_changes", force: :cascade do |t|
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.integer "user_id"
    t.integer "action_id"
    t.integer "role_id"
    t.boolean "enable"
  end

  create_table "action_roles", id: :serial, force: :cascade do |t|
    t.bigint "role_id"
    t.bigint "action_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "actions", id: :serial, force: :cascade do |t|
    t.string "action_name"
    t.integer "controller_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "human_name"
    t.index ["action_name"], name: "index_actions_on_action_name"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "activities", id: :serial, force: :cascade do |t|
    t.integer "outcome_id"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "progress"
    t.integer "index", array: true
  end

  create_table "advisory_council_documents", id: :serial, force: :cascade do |t|
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.integer "revision_major"
    t.integer "revision_minor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "lastModifiedDate"
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.string "type"
    t.datetime "date"
  end

  create_table "advisory_council_issue_issue_areas", id: :serial, force: :cascade do |t|
    t.integer "advisory_council_issue_id"
    t.integer "area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advisory_council_issue_issue_subareas", id: :serial, force: :cascade do |t|
    t.integer "advisory_council_issue_id"
    t.integer "subarea_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "advisory_council_issues", id: :serial, force: :cascade do |t|
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.string "title"
    t.datetime "lastModifiedDate"
    t.text "article_link"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "mandate_id"
  end

  create_table "advisory_council_members", id: :serial, force: :cascade do |t|
    t.string "first_name"
    t.string "last_name"
    t.string "title"
    t.string "organization"
    t.string "department"
    t.string "mobile_phone"
    t.string "office_phone"
    t.string "home_phone"
    t.string "email"
    t.string "alternate_email"
    t.string "bio"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "agencies", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "full_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "application_data_backups", id: :serial, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "areas", id: :serial, force: :cascade do |t|
    t.text "name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
  end

  create_table "assigns", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "audience_types", id: :serial, force: :cascade do |t|
    t.string "short_type"
    t.string "long_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communicants", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "title_key"
    t.string "email"
    t.string "phone"
    t.string "address"
    t.integer "organization_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communication_communicants", id: :serial, force: :cascade do |t|
    t.integer "communication_id"
    t.integer "communicant_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communication_documents", id: :serial, force: :cascade do |t|
    t.integer "communication_id"
    t.string "title", limit: 255
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.datetime "lastModifiedDate"
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "communications", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "user_id"
    t.string "direction"
    t.string "mode"
    t.datetime "date"
    t.text "note"
  end

  create_table "complaint_agencies", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "agency_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "complaint_bases", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "complaint_complaint_areas", force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "area_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "complaint_complaint_bases", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "complaint_basis_id"
    t.string "type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "complaint_complaint_subareas", force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "subarea_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "complaint_conventions", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "convention_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "complaint_documents", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.string "title", limit: 255
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.datetime "lastModifiedDate"
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "complaint_statuses", id: :serial, force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "complaints", id: :serial, force: :cascade do |t|
    t.string "case_reference"
    t.string "village"
    t.string "phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text "desired_outcome"
    t.boolean "complained_to_subject_agency"
    t.datetime "date_received"
    t.boolean "imported", default: false
    t.integer "mandate_id"
    t.string "email"
    t.string "gender", limit: 1
    t.date "dob"
    t.text "details"
    t.string "firstName"
    t.string "lastName"
    t.string "chiefly_title"
    t.string "occupation"
    t.string "employer"
  end

  create_table "controllers", id: :serial, force: :cascade do |t|
    t.string "controller_name"
    t.datetime "last_modified"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["controller_name"], name: "index_controllers_on_controller_name"
  end

  create_table "conventions", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "full_name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "csp_reports", id: :serial, force: :cascade do |t|
    t.string "document_uri"
    t.string "referrer"
    t.string "violated_directive"
    t.string "effective_directive"
    t.string "source_file"
    t.text "original_policy"
    t.text "blocked_uri"
    t.integer "status_code", default: 0
    t.integer "line_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "document_groups", id: :serial, force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type", limit: 40
    t.string "title"
    t.integer "archive_doc_count", default: 0
  end

  create_table "file_monitors", id: :serial, force: :cascade do |t|
    t.integer "indicator_id"
    t.integer "user_id"
    t.datetime "lastModifiedDate"
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.string "original_type", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "headings", id: :serial, force: :cascade do |t|
    t.string "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "human_rights_attributes", id: :serial, force: :cascade do |t|
    t.string "description"
    t.integer "heading_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "icc_reference_documents", id: :serial, force: :cascade do |t|
    t.string "source_url"
    t.string "title"
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.datetime "lastModifiedDate"
  end

  create_table "indicators", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "human_rights_attribute_id"
    t.integer "heading_id"
    t.string "nature"
    t.string "monitor_format"
    t.string "numeric_monitor_explanation"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "internal_documents", id: :serial, force: :cascade do |t|
    t.string "title"
    t.integer "filesize"
    t.string "original_filename"
    t.integer "revision_major"
    t.integer "revision_minor"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "lastModifiedDate"
    t.string "original_type"
    t.integer "document_group_id"
    t.integer "user_id"
    t.string "type", limit: 60
  end

  create_table "mandates", id: :serial, force: :cascade do |t|
    t.string "key"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media_appearance_performance_indicators", id: :serial, force: :cascade do |t|
    t.integer "media_appearance_id"
    t.integer "performance_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "media_appearances", id: :serial, force: :cascade do |t|
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.string "url"
    t.string "title"
    t.jsonb "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "lastModifiedDate"
    t.text "article_link"
    t.integer "mandate_id"
  end

  create_table "media_media_areas", force: :cascade do |t|
    t.integer "media_appearance_id"
    t.integer "area_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "media_media_subareas", force: :cascade do |t|
    t.integer "media_appearance_id"
    t.integer "subarea_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "notes", id: :serial, force: :cascade do |t|
    t.text "text"
    t.integer "notable_id"
    t.integer "author_id"
    t.integer "editor_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "notable_type"
  end

  create_table "numeric_monitors", id: :serial, force: :cascade do |t|
    t.integer "indicator_id"
    t.integer "author_id"
    t.datetime "date"
    t.integer "value"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "organizations", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "street"
    t.string "city"
    t.string "zip"
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "contacts"
    t.string "state"
  end

  create_table "outcomes", id: :serial, force: :cascade do |t|
    t.integer "planned_result_id"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "index", array: true
  end

  create_table "performance_indicators", id: :serial, force: :cascade do |t|
    t.integer "activity_id"
    t.text "description"
    t.text "target"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "index", array: true
  end

  create_table "planned_results", id: :serial, force: :cascade do |t|
    t.string "description"
    t.integer "strategic_priority_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "index", array: true
  end

  create_table "project_documents", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.string "title", limit: 255
    t.integer "filesize"
    t.string "original_filename", limit: 255
    t.datetime "lastModifiedDate"
    t.string "original_type", limit: 255
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_named_documents", id: :serial, force: :cascade do |t|
  end

  create_table "project_performance_indicators", id: :serial, force: :cascade do |t|
    t.integer "project_id"
    t.integer "performance_indicator_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "project_project_areas", force: :cascade do |t|
    t.integer "project_id"
    t.integer "area_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "project_project_subareas", force: :cascade do |t|
    t.integer "project_id"
    t.integer "subarea_id"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "projects", id: :serial, force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "mandate_id"
  end

  create_table "reminders", id: :serial, force: :cascade do |t|
    t.string "text"
    t.string "reminder_type"
    t.integer "remindable_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "remindable_type"
    t.datetime "start_date"
    t.datetime "next"
    t.integer "user_id"
  end

  create_table "role_assignments", force: :cascade do |t|
    t.bigint "assigner_id"
    t.bigint "assignee_id"
    t.string "role_name"
    t.string "action"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["assignee_id"], name: "index_role_assignments_on_assignee_id"
    t.index ["assigner_id"], name: "index_role_assignments_on_assigner_id"
  end

  create_table "roles", id: :serial, force: :cascade do |t|
    t.string "name"
    t.string "short_name"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "parent_id"
  end

  create_table "sessions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.string "session_id"
    t.datetime "login_date"
    t.datetime "logout_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_id"], name: "index_sessions_on_session_id"
  end

  create_table "settings", id: :serial, force: :cascade do |t|
    t.string "var", null: false
    t.text "value"
    t.integer "thing_id"
    t.string "thing_type", limit: 30
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["thing_type", "thing_id", "var"], name: "index_settings_on_thing_type_and_thing_id_and_var", unique: true
  end

  create_table "status_changes", id: :serial, force: :cascade do |t|
    t.integer "complaint_id"
    t.integer "user_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "complaint_status_id"
    t.datetime "change_date"
  end

  create_table "strategic_plans", id: :serial, force: :cascade do |t|
    t.date "start_date"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "title"
  end

  create_table "strategic_priorities", id: :serial, force: :cascade do |t|
    t.integer "priority_level"
    t.text "description"
    t.integer "strategic_plan_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subareas", id: :serial, force: :cascade do |t|
    t.text "name"
    t.text "full_name"
    t.integer "area_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string "type"
  end

  create_table "text_monitors", id: :serial, force: :cascade do |t|
    t.integer "indicator_id"
    t.integer "author_id"
    t.datetime "date"
    t.string "description"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "user_roles", id: :serial, force: :cascade do |t|
    t.bigint "role_id", null: false
    t.bigint "user_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "useractions", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "action_id"
    t.string "type"
    t.text "params"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "login"
    t.string "email"
    t.string "crypted_password", limit: 40
    t.string "salt", limit: 40
    t.string "activation_code", limit: 40
    t.datetime "activated_at"
    t.string "password_reset_code", limit: 40
    t.boolean "enabled", default: true
    t.string "firstName"
    t.string "lastName"
    t.string "type"
    t.string "status", default: "created"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "organization_id"
    t.string "challenge"
    t.datetime "challenge_timestamp"
    t.string "public_key"
    t.string "public_key_handle"
    t.string "replacement_token_registration_code"
    t.string "unsubscribe_code", limit: 40
    t.index ["login"], name: "index_users_on_login"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
end
