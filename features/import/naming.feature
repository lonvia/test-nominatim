@DB
Feature: Import and search of names
    Tests all naming related issues: normalisation,
    abbreviations, internationalisation, etc.


    Scenario: Case-insensitivity of search
        Given the place nodes
          | osm_id | class | type      | name
          | 1      | place | locality  | 'name' : 'FooBar'
        When importing
        Then table placex contains for N1
          | class  | type     | name
          | place  | locality | 'name' : 'FooBar'
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

    Scenario: Hyphens and slashes in name
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


    Scenario: Postcode boundaries without ref
        Given the place areas
          | osm_type | osm_id | class    | type        | postcode | geometry
          | R        | 1      | boundary | postal_code | 12345    | 0 0, 1 0, 1 1, 0 1, 0 0
        When importing
        Then query "12345" returns R1
