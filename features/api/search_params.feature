Feature: Search queries
    Testing different queries and parameters

    Scenario: Simple XML search
        When searching for "Schaan"
        Then at least 1 xml result is returned
        And xml result 1 has attributes place_id,osm_type,osm_id
        And xml result 1 has attributes place_rank,boundingbox
        And xml result 1 has attributes lat,lon,display_name
        And xml result 1 has attributes class,type,importance,icon
        And xml result 1 has no address details

    Scenario: Simple JSON search
        When searching for "Vaduz"
        Then at least 1 result is returned
        And result 1 has attributes place_id,licence,icon,class,type
        And result 1 has attributes osm_type,osm_id,boundingbox
        And result 1 has attributes lat,lon,display_name,importance
        And result 1 has not attributes address

    Scenario: JSON search with addressdetails
        When searching for "Montevideo"
        Given parameter addressdetails as "1"
        Then result 1 has address details with "Uruguay"
        And result 1 has address details in order city,state,country,country_code

    Scenario: XML search with addressdetails
        When searching for "Inuvik"
        Given parameter addressdetails as "1"
        Then xml result 1 has address details with "Canada"
        And xml result 1 has address details in order town,state,country,country_code

    Scenario: Address details with unknown class types
        When searching for "foobar, Essen"
        Given parameter addressdetails as "1"
        Then result 1 has attribute class as "leisure"
        And result 1 has attribute type as "hackerspace"
        And address 1 has details with type address29
        And address 1 has details without type leisure
        And address 1 has details without type hackerspace

    @Fail
    Scenario: Disabling deduplication
        When searching for "Oxford Street, London"
        Given parameter dedupe as "1"
        Then there are no duplicates
        Given parameter dedupe as "0"
        Then there are duplicates

    Scenario: Search with bounded viewbox in right area
        When searching for "restaurant"
        Given parameter bounded as "1"
        And parameter viewbox as "-87.7,41.9,-87.57,41.85"
        Then result 1 is in "Chicago"

    Scenario: Search with bounded viewboxlbrt in right area
        When searching for "restaurant"
        Given parameter bounded as "1"
        And parameter viewboxlbrt as "-87.7,41.85,-87.57,41.9"
        Then result 1 is in "Chicago"

    Scenario: No POI search with unbounded viewbox
        When searching for "restaurant"
        And parameter viewbox as "-87.7,41.9,-87.57,41.85"
        Then name of result 1 contains "restaurant"

    Scenario: Prefer results within viewbox
        When searching for "royan"
        And parameter accept-language as "en"
        Then result 1 is in "France"    
        When searching for "royan"
        And parameter viewbox as "51.94,36.59,51.99,36.56"
        And parameter accept-language as "en"
        Then result 1 is in "Iran"    

    Scenario: Overly large limit number for search results
        When searching for "Neustadt"
        And parameter limit as "1000"
        Then at most 50 results are returned

    Scenario: Limit number of search results
        When searching for "Neustadt"
        And parameter limit as "4"
        Then exactly 4 results are returned

    Scenario: Restrict to feature type country
        When searching for "Monaco"
        And parameter featureType as "country"
        Then result 1 has rank 4 to 4

    Scenario: Restrict to feature type state
        When searching for "Berlin"
        Then result 1 has rank 15 to 16
        When searching for "Berlin"
        And parameter featureType as "state"
        Then result 1 has rank 7 to 8

    Scenario: Restrict to feature type city
        When searching for "Monaco"
        Given parameter featureType as "city"
        Then result 1 has rank 14 to 16


    Scenario: Restrict to feature type settlement
        When searching for "Everest"
        Then name of result 1 contains "Mount Everest" 
        When searching for "Everest"
        Given parameter addressdetails as "1"
        And parameter featuretype as "settlement"
        Then result 1 has address details without "Mount Everest"
