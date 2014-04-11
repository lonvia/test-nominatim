@DB
Feature: Import into placex
    Tests that data in placex is completed correctly.

    Scenario: No country code tag is available
        Given the place nodes
          | osm_id | class   | type     | name           | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | country:us
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | N1     | None         | us                      |

    Scenario: Location overwrites country code tag
        Given the scenario country
        And the place nodes
          | osm_id | class   | type     | name           | country_code | geometry
          | 1      | highway | primary  | 'name' : 'A1'  | de           | :us
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | N1     | de           | us                      |

    Scenario: Country code tag overwrites location for countries
        Given the scenario country
        And the place areas
          | osm_type | osm_id | class    | type            | admin_level | name            | country_code | geometry
          | R        | 1      | boundary | administrative  | 2           | 'name' : 'foo'  | de           | (-100 40, -101 40, -101 41, -100 41, -100 40)
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | R1     | de           | de                      |

    Scenario: Illegal country code tag for countries is ignored
        Given the scenario country
        And the place areas
          | osm_type | osm_id | class    | type            | admin_level | name            | country_code | geometry
          | R        | 1      | boundary | administrative  | 2           | 'name' : 'foo'  | xx          | (-100 40, -101 40, -101 41, -100 41, -100 40)
        When importing
        Then table placex contains
          | object | country_code | calculated_country_code |
          | R1     | xx           | us                      |

    Scenario: admin level is copied over
        Given the place nodes
          | osm_id | class | type      | admin_level | name
          | 1      | place | state     | 3           | 'name' : 'foo'
        When importing
        Then table placex contains
          | object | admin_level |
          | N1     | 3           |

    Scenario: admin level is default 15
        Given the place nodes
          | osm_id | class   | type      | name
          | 1      | amenity | prison    | 'name' : 'foo'
        When importing
        Then table placex contains
          | object | admin_level |
          | N1     | 15          |

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
          | R        | 1      | boundary | postal_code | (0 0, 1 0, 1 1, 0 1, 0 0)
        When importing
        Then table placex has no entry for R1

    Scenario: search and address ranks for GB post codes correctly assigned
        Given the place nodes
         | osm_id  | class | type     | postcode | geometry
         | 1       | place | postcode | E45 2CD  | country:gb
         | 2       | place | postcode | E45 2    | country:gb
         | 3       | place | postcode | Y45      | country:gb
        When importing
        Then table placex contains
         | object | postcode | calculated_country_code | rank_search | rank_address
         | N1     | E45 2CD  | gb                      | 25          | 5
         | N2     | E45 2    | gb                      | 23          | 5
         | N3     | Y45      | gb                      | 21          | 5

    Scenario: wrongly formatted GB postcodes are down-ranked
        Given the place nodes
         | osm_id  | class | type     | postcode | geometry
         | 1       | place | postcode | EA452CD  | country:gb
         | 2       | place | postcode | E45 23   | country:gb
         | 3       | place | postcode | y45      | country:gb
        When importing
        Then table placex contains
         | object | calculated_country_code | rank_search | rank_address
         | N1     | gb                      | 30          | 30
         | N2     | gb                      | 30          | 30
         | N3     | gb                      | 30          | 30

    Scenario: search and address rank for DE postcodes correctly assigned
        Given the place nodes
         | osm_id  | class | type     | postcode | geometry
         | 1       | place | postcode | 56427    | country:de
         | 2       | place | postcode | 5642     | country:de
         | 3       | place | postcode | 5642A    | country:de
         | 4       | place | postcode | 564276   | country:de
        When importing
        Then table placex contains
         | object | calculated_country_code | rank_search | rank_address
         | N1     | de                      | 21          | 11
         | N2     | de                      | 30          | 30
         | N3     | de                      | 30          | 30
         | N4     | de                      | 30          | 30

    Scenario: search and address rank for other postcodes are correctly assigned
        Given the place nodes
         | osm_id  | class | type     | postcode | geometry
         | 1       | place | postcode | 1        | country:ca
         | 2       | place | postcode | X3       | country:ca
         | 3       | place | postcode | 543      | country:ca
         | 4       | place | postcode | 54dc     | country:ca
         | 5       | place | postcode | 12345    | country:ca
         | 6       | place | postcode | 55TT667  | country:ca
         | 7       | place | postcode | 123-65   | country:ca
         | 8       | place | postcode | 12 445 4 | country:ca
         | 9       | place | postcode | A1:bc10  | country:ca
        When importing
        Then table placex contains
         | object | calculated_country_code | rank_search | rank_address
         | N1     | ca                      | 21          | 11
         | N2     | ca                      | 21          | 11
         | N3     | ca                      | 21          | 11
         | N4     | ca                      | 21          | 11
         | N5     | ca                      | 21          | 11
         | N6     | ca                      | 21          | 11
         | N7     | ca                      | 25          | 11
         | N8     | ca                      | 25          | 11
         | N9     | ca                      | 25          | 11


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
