@DB
Feature: Import into placex
    Tests that data in placex is completed correctly.

    Scenario: Country code tag available
        Given the place nodes
          | osm_id | class | type      | name           | country_code
          | 1      | place | locality  | 'name' : 'foo' | de
        When importing
        Then column 'country_code' in placex contains 'de' for N1

    Scenario: No country code tag is available
        Given the place nodes
          | osm_id | class   | type     | name           | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | -100,40
        When importing
        Then column 'country_code' in placex contains nothing for N1
        And column 'calculated_country_code' in placex contains 'us' for N1

    Scenario: Location overwrites country code tag
        Given the place nodes
          | osm_id | class   | type     | name           | country_code | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | de           | -100,40
        When importing
        Then column 'country_code' in placex contains 'de' for N1
        And column 'calculated_country_code' in placex contains 'us' for N1


    Scenario: admin level is copied over
        Given the place nodes
          | osm_id | class | type      | admin_level | name
          | 1      | place | state     | 3           | 'name' : 'foo'
        When importing
        Then column 'admin_level' in placex contains '3' for N1

    Scenario: admin level is default null
        Given the place nodes
          | osm_id | class   | type      | name
          | 1      | amenity | prison    | 'name' : 'foo'
        When importing
        Then column 'admin_level' in placex contains nothing for N1

    Scenario: admin level is never larger than 15
        Given the place nodes
          | osm_id | class   | type      | name           | admin_level
          | 1      | amenity | prison    | 'name' : 'foo' | 16
        When importing
        Then column 'admin_level' in placex contains '15' for N1

    Scenario: postcode node without postcode is dropped
        Given the place nodes
          | osm_id | class   | type
          | 1      | place   | postcode
        When importing
        Then table placex has no entry for N1

    Scenario: postcode boundary without postcode is dropped
        Given the place areas
          | osm_type | osm_id | class    | type        | geometry
          | R        | 1      | boundary | postal_code | 0 0, 1 0, 1 1, 0 1, 0 0
        When importing
        Then table placex has no entry for R1

