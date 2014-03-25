@DB
Feature: Update of names in place objects
    Test all naming relatied issues in updates


    Scenario: Updating postcode in postcode boundaries without ref
        Given the place areas
          | osm_type | osm_id | class    | type        | postcode | geometry
          | R        | 1      | boundary | postal_code | 12345    | 0 0, 1 0, 1 1, 0 1, 0 0
        When importing
        Then query "12345" returns R1
        When updating place areas
          | osm_type | osm_id | class    | type        | postcode | geometry
          | R        | 1      | boundary | postal_code | 54321    | 0 0, 1 0, 1 1, 0 1, 0 0
        And query "12345" returns nothing
        Then query "54321" returns R1


    Scenario: Delete postcode from postcode boundaries without ref
        Given the place areas
          | osm_type | osm_id | class    | type        | postcode | geometry
          | R        | 1      | boundary | postal_code | 12345    | 0 0, 1 0, 1 1, 0 1, 0 0
        When importing
        Then query "12345" returns R1
        When updating place areas
          | osm_type | osm_id | class    | type        | geometry
          | R        | 1      | boundary | postal_code | 0 0, 1 0, 1 1, 0 1, 0 0
        Then table placex has no entry for R1

