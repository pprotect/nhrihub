select * 
  from (
    select ( 
      ( select (regexp_matches(complaints.case_reference, '(?:sequence: (\d*))'))[1]) 
        ||
        (regexp_matches(complaints.case_reference, '(?:year: (\d*))'))[1])
      as bar
      from complaints)
    foo where bar ~ '^320';
