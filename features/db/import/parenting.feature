@DB
Feature: Parenting of objects
    Tests that the correct parent is choosen

    Scenario: Address without tags, closest street
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :p-N1
         | 2      | place | house | :p-N2
         | 3      | place | house | :p-S1
         | 4      | place | house | :p-S2
        And the named place ways
         | osm_id | class   | type        | geometry
         | 1      | highway | residential | :w-north
         | 2      | highway | residential | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W2
         | N4     | W2

    Scenario: Address without tags avoids unnamed streets
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :p-N1
         | 2      | place | house | :p-N2
         | 3      | place | house | :p-S1
         | 4      | place | house | :p-S2
        And the place ways
         | osm_id | class   | type        | geometry
         | 1      | highway | residential | :w-north
        And the named place ways
         | osm_id | class   | type        | geometry
         | 2      | highway | residential | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W2
         | N2     | W2
         | N3     | W2
         | N4     | W2

    Scenario: addr:street tag parents to appropriately named street
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | street| geometry
         | 1      | place | house | south | :p-N1
         | 2      | place | house | north | :p-N2
         | 3      | place | house | south | :p-S1
         | 4      | place | house | north | :p-S2
        And the place ways
         | osm_id | class   | type        | name             | geometry
         | 1      | highway | residential | 'name' : 'north' | :w-north
         | 2      | highway | residential | 'name' : 'south' | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W2
         | N2     | W1
         | N3     | W2
         | N4     | W1

    Scenario: addr:street tag parents to next named street
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | street | geometry
         | 1      | place | house | abcdef | :p-N1
         | 2      | place | house | abcdef | :p-N2
         | 3      | place | house | abcdef | :p-S1
         | 4      | place | house | abcdef | :p-S2
        And the place ways
         | osm_id | class   | type        | name              | geometry
         | 1      | highway | residential | 'name' : 'abcdef' | :w-north
         | 2      | highway | residential | 'name' : 'abcdef' | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W2
         | N4     | W2

    Scenario: addr:street tag without appropriately named street
        Given the scene roads-with-pois
        And the place nodes
         | osm_id | class | type  | street | geometry
         | 1      | place | house | abcdef | :p-N1
         | 2      | place | house | abcdef | :p-N2
         | 3      | place | house | abcdef | :p-S1
         | 4      | place | house | abcdef | :p-S2
        And the place ways
         | osm_id | class   | type        | name             | geometry
         | 1      | highway | residential | 'name' : 'abcde' | :w-north
         | 2      | highway | residential | 'name' : 'abcde' | :w-south
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W2
         | N4     | W2

    Scenario: Untagged address in simple associated street relation
        Given the scene road-with-alley
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :n-alley
         | 2      | place | house | :n-corner
         | 3      | place | house | :n-main-west
        And the place ways
         | osm_id | class   | type        | name           | geometry
         | 1      | highway | residential | 'name' : 'foo' | :w-main
         | 2      | highway | service     | 'name' : 'bar' | :w-alley
        And the relations
         | id | members            | tags
         | 1  | W1:street,N1,N2,N3 | 'type' : 'associatedStreet'
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W1
         
    Scenario: Avoid unnamed streets in simple associated street relation
        Given the scene road-with-alley
        And the place nodes
         | osm_id | class | type  | geometry
         | 1      | place | house | :n-alley
         | 2      | place | house | :n-corner
         | 3      | place | house | :n-main-west
        And the named place ways
         | osm_id | class   | type        | geometry
         | 1      | highway | residential | :w-main
        And the place ways
         | osm_id | class   | type        | geometry
         | 2      | highway | residential | :w-alley
        And the relations
         | id | members            | tags
         | 1  | N1,N2,N3,W2:street,W1:street | 'type' : 'associatedStreet'
        When importing
        Then table placex contains
         | object | parent_place_id
         | N1     | W1
         | N2     | W1
         | N3     | W1
