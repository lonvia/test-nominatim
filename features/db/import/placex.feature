@DB
Feature: Import into placex
    Tests that data in placex is completed correctly.

    Scenario: No country code tag is available
        Given the place nodes
          | osm_id | class   | type     | name           | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | -100,40
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | N1     | None         | us                      |

    Scenario: Location overwrites country code tag
        Given the place nodes
          | osm_id | class   | type     | name           | country_code | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | de           | -100,40
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | N1     | de           | us                      |


    Scenario: admin level is copied over
        Given the place nodes
          | osm_id | class | type      | admin_level | name
          | 1      | place | state     | 3           | 'name' : 'foo'
        When importing
        Then table placex contains
          | object | admin_level |
          | N1     | 3           |

    Scenario: admin level is default null
        Given the place nodes
          | osm_id | class   | type      | name
          | 1      | amenity | prison    | 'name' : 'foo'
        When importing
        Then table placex contains
          | object | admin_level |
          | N1     | None        |

    Scenario: admin level is never larger than 15
        Given the place nodes
          | osm_id | class   | type      | name           | admin_level
          | 1      | amenity | prison    | 'name' : 'foo' | 16
        When importing
        Then table placex contains
          | object | admin_level |
          | N1     | 15          |

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
        Then table placex contains
          | object | rank_search | rank_address |
          | N1     | 30          | 30 |
          | N11    | 30          | 30 |
          | N12    | 2           | 2 |
          | N13    | 2           | 0 |
          | N14    | 4           | 4 |
          | N15    | 8           | 8 |
          | N16    | 18          | 0 |
          | N17    | 12          | 12 |
          | N18    | 16          | 16 |
          | N19    | 17          | 0 |
          | N20    | 18          | 16 |
          | N21    | 19          | 16 |
          | N22    | 19          | 16 |
          | N23    | 19          | 16 |
          | N24    | 19          | 16 |
          | N25    | 19          | 16 |
          | N26    | 19          | 16 |
          | N27    | 20          | 20 |
          | N28    | 20          | 20 |
          | N29    | 20          | 20 |
          | N30    | 20          | 20 |
          | N31    | 20          | 0 |
          | N32    | 20          | 0 |
          | N33    | 20          | 0 |
          | N34    | 20          | 0 |
          | N100   | 20          | 20 |
          | N35    | 22          | 22 |
          | N36    | 30          | 30 |
          | N37    | 30          | 30 |
          | N38    | 28          | 0 |
