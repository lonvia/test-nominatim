Feature: API regression tests
    Tests error cases reported in tickets.

    Scenario: trac #2430
        When sending json search query "89 River Avenue, Hoddesdon, Hertfordshire, EN11 0JT"
        Then at least 1 result is returned

    Scenario: trac #2440
        When sending json search query "East Harvard Avenue, Denver"
        Then more than 2 results are returned

    Scenario: trac #2456
        When sending xml search query "Borlänge Kommun"
        Then results contain
         | ID | place_rank
         | 0  | 19

    Scenario: trac #2530
        When sending json search query "Lange Straße, Bamberg" with address
        Then result addresses contain
         | ID | town
         | 0  | Bamberg

    Scenario: trac #2541
        When sending json search query "pad, germany"
        Then results contain
         | ID | class   | display_name
         | 0  | aeroway | Paderborn/Lippstadt,.*

    Scenario: trac #2579
        When sending json search query "Johnsons Close, hackbridge" with address
        Then result addresses contain
         | ID | postcode
         | 0  | SM5 2LU
