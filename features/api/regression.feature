Feature: API regression tests
    Tests error cases reported in tickets.

    @Fail
    Scenario Outline: github #36
        When sending json search query "<query>" with address
        Then result addresses contain
         | ID | road     | city
         | 0  | Seegasse | Gemeinde Wieselburg-Land

    Examples:
         | query
         | Seegasse, Gemeinde Wieselburg-Land
         | Seegasse, Wieselburg-Land
         | Seegasse, Wieselburg

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

    @Fail
    Scenario Outline: trac #2586
        When sending json search query "<query>" with address
        Then result addresses contain
         | ID | country_code
         | 0  | uk

    Examples:
        | query
        | DL7 0SN
        | DL70SN

    Scenario: trac #2628 (1)
        When sending json search query "Adam Kraft Str" with address
        Then result addresses contain
         | ID | road          
         | 0  | Adam-Kraft-Straße

    Scenario: trac #2628 (2)
        When sending json search query "Maxfeldstr. 5, Nürnberg" with address
        Then result addresses contain
         | ID | house_number | road          | city
         | 0  | 5            | Maxfeldstraße | Nürnberg

    Scenario: trac #2638
        When sending json search query "Nöthnitzer Str. 40, 01187 Dresden" with address
        Then result addresses contain
         | ID | house_number | road              | city
         | 0  | 40           | Nöthnitzer Straße | Dresden

    Scenario Outline: trac #2667
        When sending json search query "<query>" with address
        Then result addresses contain
         | ID | house_number
         | 0  | <number>

    Examples:
        | number | query
        | 16     | 16 Woodpecker Way, Cambourne
        | 14906  | 14906, 114 Street Northwest, Edmonton, Alberta, Canada
        | 14904  | 14904, 114 Street Northwest, Edmonton, Alberta, Canada
        | 15022  | 15022, 114 Street Northwest, Edmonton, Alberta, Canada
        | 15024  | 15024, 114 Street Northwest, Edmonton, Alberta, Canada

    Scenario: trac #2681
        When sending json search query "kirchstraße troisdorf Germany"
        Then results contain
         | ID | display_name
         | 0  | .*, Troisdorf, .*
