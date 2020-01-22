require 'active_support/concern'
module ComplaintQuery
  extend ActiveSupport::Concern

  class_methods do
    def with_case_reference_match(case_ref_fragment)
      sql = CaseReference.sql_match(case_ref_fragment)
      where(sql)
    end

    # can take either an array of strings or symbols
    # or cant take a single string or symbol
    def with_status(status_ids)
      joins(:status_changes => :complaint_status).
        merge(StatusChange.most_recent_for_complaint).
        merge(ComplaintStatus.with_status(status_ids))
    end

    def for_assignee(user_id = nil)
      user_id && !user_id.blank? ?
        select('distinct complaints.id, complaints.*, assigns.created_at, assigns.user_id, assigns.complaint_id').joins(:assigns).merge(Assign.most_recent_for_assignee(user_id)) :
        where("1=0")
    end

    def with_agencies(selected_agency_ids, options = {})
      if options[:match] == :exact
        return no_results if selected_agency_ids.nil? || selected_agency_ids.empty?
      else
        return no_filter if Agency.count.zero?
        return no_filter if selected_agency_ids.delete_if(&:blank?).empty?
        #selected_agency_ids = nil if selected_agency_ids.delete_if(&:blank?).empty?
      end
      joins(:complaint_agencies).where("complaint_agencies.agency_id in (?)", selected_agency_ids)
    end

    def no_results
      where("1=0")
    end

    def no_filter
      where("1=1")
    end

    def with_subareas(selected_subarea_ids)
      return no_filter if ComplaintSubarea.count.zero?
      selected_subarea_ids = nil if selected_subarea_ids.delete_if(&:blank?).empty?

      joins(:complaint_complaint_subareas).
        where( "complaint_complaint_subareas.subarea_id in (?)", selected_subarea_ids)
    end

    def with_complaint_area_ids(selected_complaint_area_ids)
      return no_filter if ComplaintArea.count.zero?
      where(complaint_area_id: selected_complaint_area_ids)
    end

    def with_phone(phone_fragment)
      digits = phone_fragment&.delete('^0-9')
      return no_filter if digits.nil? || digits.empty?
      #where("complaints.phone ~ '.*#{digits}.*'")
      digits_regex = digits.chars.join("[^[:digit:]]*")
      where("home_phone ~ '#{digits_regex}' OR cell_phone ~ '#{digits_regex}' OR fax ~ '#{digits_regex}'")
    end

    def with_city(city_fragment)
      return no_filter if city_fragment.blank?
      where("\"complaints\".\"city\" ~* '.*#{city_fragment}.*'")
    end

    def since_date(from)
      return no_filter if from.blank?
      time_from = Time.zone.local_to_utc(Time.parse(from)).beginning_of_day
      where("complaints.date_received >= ?", time_from)
    end

    def before_date(to)
      return no_filter if to.blank?
      where("complaints.date_received <= ?", Time.parse(to).end_of_day)
    end

    def with_complainant_fragment_match(complainant_fragment)
      return no_filter if complainant_fragment.blank?
      sql = "\"complaints\".\"firstName\" || ' ' || \"complaints\".\"lastName\" ~* '.*#{complainant_fragment}.*'"
      where(sql)
    end

    # {"id_value"=>"1234abcd",
    # "alt_id_value"=>"88bcd44efg",
    # "lastName"=>"McMurtry",
    # "email"=>"norm@acme.co.za",
    # "agency_ids"=>["439", "433", "434", "435"]}
    def with_duplicate_individual_complainant(params)
      params = params.to_h.symbolize_keys
      query = []
      query << '"complaints"."id_value" = :id_value' unless params[:id_value].blank?
      query << '"complaints"."alt_id_value" = :alt_id_value' unless params[:alt_id_value].blank?
      query << '"complaints"."lastName" = :lastName' unless params[:lastName].blank?
      query << '"complaints"."email" = :email' unless params[:email].blank?
      query = query.join(' or ')
      query = "1 = 0" if query.blank?
      where(query, params).sort_by(&:case_reference)
    end

    def with_duplicate_organization_complainant(params)
      params = params.to_h.symbolize_keys
      query = []
      query << '"complaints"."organization_name" = :organization_name' unless params[:organization_name].blank?
      query << '"complaints"."organization_registration_number" = :organization_registration_number' unless params[:organization_registration_number].blank?
      query = query.join(' or ')
      query = "1 = 0" if query.blank?
      where(query, params).sort_by(&:case_reference)
    end

    def with_duplicate_own_motion_complainant(params)
      params = params.to_h.symbolize_keys
      query = []
      query << '"complaints"."initiating_branch_id" = :initiating_branch_id' unless params[:initiating_branch_id].blank?
      query << '"complaints"."initiating_office_id" = :initiating_office_id' unless params[:initiating_office_id].blank?
      query = query.join(' or ')
      query = "1 = 0" if query.blank?
      where(query, params).sort_by(&:case_reference)
    end

  end
end
