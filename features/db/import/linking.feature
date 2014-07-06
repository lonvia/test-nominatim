@DB
Feature: Linking of places
    Tests for correctly determining linked places

    Scenario: Waterways are linked when in waterway relations
        Given the scene split-road
        And the place ways
         | osm_type | osm_id | class    | type  | name  | geometry
         | W        | 1      | waterway | river | Rhein | :w-2
         | W        | 2      | waterway | river | Rhein | :w-3
         | R        | 13     | waterway | river | Rhein | :w-1 + :w-2 + :w-3
         | R        | 23     | waterway | river | Limmat| :w-4a
        And the relations
         | id | members                          | tags
         | 13 | R23:tributary,W1,W2:main_stream  | 'type' : 'waterway'
        When importing
        Then table placex contains
         | object | linked_place_id
         | W1     | R13
         | W2     | R13
         | R13    | None
         | R23    | None
        When sending query "rhein"
        Then results contain
         | osm_type
         | R

    Scenario: Relations are not linked when in waterway relations
        Given the scene split-road
        And the place ways
         | osm_type | osm_id | class    | type  | name  | geometry
         | W        | 1      | waterway | river | Rhein | :w-2
         | W        | 2      | waterway | river | Rhein | :w-3
         | R        | 1      | waterway | river | Rhein | :w-1 + :w-2 + :w-3
         | R        | 2      | waterway | river | Limmat| :w-4a
        And the relations
         | id | members                          | tags
         | 13 | R2                               | 'type' : 'waterway'
        When importing
        Then table placex contains
         | object | linked_place_id
         | W1     | None
         | W2     | None
         | R1     | None
         | R2     | None

    Scenario: Waterways are not linked when in non-waterway relations
        Given the scene split-road
        And the place ways
         | osm_type | osm_id | class    | type     | name  | geometry
         | W        | 1      | waterway | drain    | Rhein | :w-2
         | R        | 1      | waterway | river    | Rhein | :w-1 + :w-2 + :w-3
        And the relations
         | id | members               | tags
         | 1  | N23,N34,W1,R45        | 'type' : 'multipolygon'
        When importing
        Then table placex contains
         | object | linked_place_id
         | W1     | None
         | R1     | None
        When sending query "rhein"
        Then results contain
          | ID | osm_type
          |  0 | R
          |  1 | W

    Scenario: Waterways are not linked when in waterway relations is a side stream
        Given the scene split-road
        And the place ways
         | osm_type | osm_id | class    | type  | name   | geometry
         | W        | 1      | waterway | river | Rhein2 | :w-2
         | R        | 1      | waterway | river | Rhein  | :w-1 + :w-2 + :w-3
        And the relations
         | id | members            | tags
         | 1  | W1:side_stream     | 'type' : 'waterway'
        When importing
        Then table placex contains
         | object | linked_place_id
         | W1     | None
        When sending query "rhein2"
        Then results contain
         | osm_type
         | W
