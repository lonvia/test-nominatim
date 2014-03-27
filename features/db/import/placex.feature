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

    Scenario: search and address ranks for places are correctly assigned
        Given the named place nodes
          | osm_id | class     | type      | 
          | 1      | foo       | bar       |
          | 11     | place     | Continent |
          | 12     | place     | continent |
          | 13     | place     | sea       |
          | 14     | place     | country   |
          | 15     | place     | state     |
          | 16     | place     | region    |
          | 17     | place     | county    |
          | 18     | place     | city      |
          | 19     | place     | island    |
          | 20     | place     | town      |
          | 21     | place     | village   |
          | 22     | place     | hamlet    |
          | 23     | place     | municipality |
          | 24     | place     | district     |
          | 25     | place     | unincorporated_area |
          | 26     | place     | borough             |
          | 27     | place     | suburb              |
          | 28     | place     | croft               |
          | 29     | place     | subdivision         |
          | 30     | place     | isolated_dwelling   |
          | 31     | place     | farm                |
          | 32     | place     | locality            |
          | 33     | place     | islet               |
          | 34     | place     | mountain_pass       |
          | 35     | place     | neighbourhood       |
          | 36     | place     | house               |
          | 37     | place     | building            |
          | 38     | place     | houses              |
        And the named place nodes
          | osm_id | class     | type      | extratags               |
          | 100    | place     | locality  | 'locality' : 'townland' |
        When importing
        Then placex ranking for N1 is 30/30
        Then placex ranking for N11 is 30/30
        Then placex ranking for N12 is 2/2
        Then placex ranking for N13 is 2/0
        Then placex ranking for N14 is 4/4
        Then placex ranking for N15 is 8/8
        Then placex ranking for N16 is 18/0
        Then placex ranking for N17 is 12/12
        Then placex ranking for N18 is 16/16
        Then placex ranking for N19 is 17/0
        Then placex ranking for N20 is 18/16
        Then placex ranking for N21 is 19/16
        Then placex ranking for N22 is 19/16
        Then placex ranking for N23 is 19/16
        Then placex ranking for N24 is 19/16
        Then placex ranking for N25 is 19/16
        Then placex ranking for N26 is 19/16
        Then placex ranking for N27 is 20/20
        Then placex ranking for N28 is 20/20
        Then placex ranking for N29 is 20/20
        Then placex ranking for N30 is 20/20
        Then placex ranking for N31 is 20/0
        Then placex ranking for N32 is 20/0
        Then placex ranking for N33 is 20/0
        Then placex ranking for N34 is 20/0
        Then placex ranking for N100 is 20/20
        Then placex ranking for N35 is 22/22
        Then placex ranking for N36 is 30/30
        Then placex ranking for N37 is 30/30
        Then placex ranking for N38 is 28/0

