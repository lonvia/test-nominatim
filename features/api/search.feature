Feature: Search queries
    Testing correctness of results

    Scenario: UK House number search
        When searching for "27 Thoresby Road, Broxtowe"
        Then address 1 contains the following:
          | type         | value
          | house_number | 27
          | road         | Thoresby Road
          | city         | Broxtowe
          | state        | England
          | country      | United Kingdom
          | country_code | gb


    Scenario: House number search for non-street address
        When searching for "4 Pomocnia, Poland"
        Given language "en"
        Then address 1 contains the following:
          | type         | value
          | house_number | 4
          | suburb       | Pomocnia
          | country      | Poland
          | country_code | pl
        And address 1 has details without type road

    Scenario: House number interpolation even
        When searching for "140 rue Don Bosco, Saguenay"
        Given language "en"
        Then address 1 contains the following:
          | type         | value
          | house_number | 140
          | road         | rue Don Bosco
          | city         | Saguenay
          | state        | Quebec
          | country      | Canada
          | country_code | ca

    Scenario: House number interpolation odd
        When searching for "141 rue Don Bosco, Saguenay"
        Given language "en"
        Then address 1 contains the following:
          | type         | value
          | house_number | 141
          | road         | rue Don Bosco
          | city         | Saguenay
          | state        | Quebec
          | country      | Canada
          | country_code | ca

    Scenario: TIGER house number
        When searching for "3 West Victory Way, Craig"
        Then result 1 has not attributes osm_id,osm_type

    Scenario: TIGER house number (road fallback)
        When searching for "3030 West Victory Way, Craig"
        Then result 1 has attributes osm_id,osm_type

    Scenario: Expansion of Illinois
        When searching for "il, us"
        Using language "en"
        Then result 1 starts with "Illinois"
