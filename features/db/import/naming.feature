@DB
Feature: Import and search of names
    Tests all naming related issues: normalisation,
    abbreviations, internationalisation, etc.


    Scenario: Case-insensitivity of search
        Given the place nodes
          | osm_id | class | type      | name
          | 1      | place | locality  | 'name' : 'FooBar'
        When importing
        Then table placex contains
          | object | class  | type     | name
          | N1     | place  | locality | 'name' : 'FooBar'
        And query "FooBar" returns N1
        And query "foobar" returns N1
        And query "fOObar" returns N1
        And query "FOOBAR" returns N1

    Scenario: Multiple spaces in name
        Given the place nodes
          | osm_id | class | type      | name
          | 1      | place | locality  | 'name' : 'one two  three'
        When importing
        Then query "one two three" returns N1
        And query "one  two three" returns N1
        And query "one two  three" returns N1
        And query "   one two three" returns N1

    Scenario: Special characters in name
        Given the place nodes
          | osm_id | class | type      | name
          | 1      | place | locality  | 'name' : 'Jim-Knopf-Str'
          | 2      | place | locality  | 'name' : 'Smith/Weston'
          | 3      | place | locality  | 'name' : 'space mountain'
          | 4      | place | locality  | 'name' : 'space'
          | 5      | place | locality  | 'name' : 'mountain'
        When importing
        Then query "Jim-Knopf-Str" returns N1
        And query "Jim Knopf-Str" returns N1
        And query "Jim Knopf Str" returns N1
        And query "Jim/Knopf-Str" returns N1
        And query "Smith/Weston" returns N2
        And query "Smith Weston" returns N2
        And query "Smith-Weston" returns N2
        And query "space mountain" returns N3
        And query "space-mountain" returns N3
        And query "space/mountain" returns N3
        And query "space\mountain" returns N3
        And query "space(mountain)" returns N3

    Scenario: No copying name tag if only one name
        Given the place nodes
          | osm_id | class | type      | name              | geometry
          | 1      | place | locality  | 'name' : 'german' | country:de
        When importing
        Then table placex contains
          | object | calculated_country_code |
          | N1     | de
        And table placex contains as names for N1
          | object | k       | v
          | N1     | name    | german

    Scenario: Copying name tag to default language if it does not exist
        Given the place nodes
          | osm_id | class | type      | name                                     | geometry
          | 1      | place | locality  | 'name' : 'german', 'name:fi' : 'finnish' | country:de
        When importing
        Then table placex contains
          | object | calculated_country_code |
          | N1     | de
        And table placex contains as names for N1
          | k       | v
          | name    | german
          | name:fi | finnish
          | name:de | german

    Scenario: Copying default language name tag to name if it does not exist
        Given the place nodes
          | osm_id | class | type      | name                                        | geometry
          | 1      | place | locality  | 'name:de' : 'german', 'name:fi' : 'finnish' | country:de
        When importing
        Then table placex contains
          | object | calculated_country_code |
          | N1     | de
        And table placex contains as names for N1
          | k       | v
          | name    | german
          | name:fi | finnish
          | name:de | german

    Scenario: Do not overwrite default language with name tag
        Given the place nodes
          | osm_id | class | type      | name                                                          | geometry
          | 1      | place | locality  | 'name' : 'german', 'name:fi' : 'finnish', 'name:de' : 'local' | country:de
        When importing
        Then table placex contains
          | object | calculated_country_code |
          | N1     | de
        And table placex contains as names for N1
          | k       | v
          | name    | german
          | name:fi | finnish
          | name:de | local

    Scenario: Landuse without name are ignored
        Given the place areas
          | osm_type | osm_id | class    | type        | geometry
          | R        | 1      | natural  | meadow      | (0 0, 1 0, 1 1, 0 1, 0 0)
          | R        | 2      | landuse  | industrial  | (0 0, -1 0, -1 -1, 0 -1, 0 0)
        When importing
        Then table placex has no entry for R1
        And table placex has no entry for R2

    Scenario: Landuse with name are found
        Given the place areas
          | osm_type | osm_id | class    | type        | name                | geometry
          | R        | 1      | natural  | meadow      | 'name' : 'landuse1' | (0 0, 1 0, 1 1, 0 1, 0 0)
          | R        | 2      | landuse  | industrial  | 'name' : 'landuse2' | (0 0, -1 0, -1 -1, 0 -1, 0 0)
        When importing
        Then query "landuse1" returns R1
        And query "landuse2" returns R2

    Scenario: Postcode boundaries without ref
        Given the place areas
          | osm_type | osm_id | class    | type        | postcode | geometry
          | R        | 1      | boundary | postal_code | 12345    | (0 0, 1 0, 1 1, 0 1, 0 0)
        When importing
        Then query "12345" returns R1

