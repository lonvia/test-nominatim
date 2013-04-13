Feature: Simple Tests
    Simple tests for internal server errors and response format.
    These tests should pass on any Nominatim installation.

    Scenario Outline: Testing different parameters
        When searching for "Manchester"
        Given parameter <parameter> as "<value>"
        Then valid html is returned
        Using format html
        Then valid html is returned
        Using format xml
        Then valid search xml is returned
        Using format json
        Then valid json is returned
        Using format jsonv2
        Then valid json is returned

    Examples:
     | parameter        | value
     | addressdetails   | 1
     | addressdetails   | 0
     | polygon_text     | 1
     | polygon_text     | 0
     | polygon_kml      | 1
     | polygon_kml      | 0
     | polygon_geojson  | 1
     | polygon_geojson  | 0
     | polygon_svg      | 1
     | accept-language  | de,en
     | countrycodes     | uk,ir
     | bounded          | 1
     | bounded          | 0
     | exclude_place_ids| 385252,1234515
     | limit            | 1000
     | dedupe           | 1
     | dedupe           | 0

    Scenario Outline: Simple Searches
        When searching for "<query>"
        Then valid html is returned
        Using format html
        Then valid html is returned
        Using format json
        Then valid json is returned
        Using format jsonv2
        Then valid json is returned

    Examples:
     | query
     | New York, New York
     | France
     | 12, Main Street, Houston
     | München
     | 東京都
     | hotels in nantes
     | xywxkrf
     | gh; foo()
     | %#$@*&l;der#$!
     | 234

    Scenario: Empty XML search
        When searching for "xnznxvcx"
        Given format xml
        Then valid search xml is returned
        And xml header contains attribute querystring as "xnznxvcx"
        And xml header contains attribute polygon as "false"
        And xml more url consists of
        | param   | value
        | format  | xml
        | q       | xnznxvcx

    Scenario: Empty XML search with special XML characters
        When searching for "xfdghn&zxn"xvbyx<vxx>cssdex"
        Given format xml
        Then valid search xml is returned
        And xml header contains attribute querystring as "xfdghn&zxn"xvbyx<vxx>cssdex"
        And xml header contains attribute polygon as "false"
        And xml more url consists of
        | param   | value
        | format  | xml
        | q       | xfdghn&zxn"xvbyx<vxx>cssdex

    Scenario: Empty XML search with viewbox
        When searching for "xnznxvcx"
        Given format xml
        And parameter viewbox as "12,34.13,77,45"
        Then valid search xml is returned
        And xml header contains attribute querystring as "xnznxvcx"
        And xml header contains attribute polygon as "false"
        And xml contains a viewbox of 12,34.13,77,45


    Scenario: Empty XML search with polygon values
        When searching for "xnznxvcx"
        Given format xml
        And parameter polygon as "<polyval>"
        Then valid search xml is returned
        And xml header contains attribute polygon as "<result>"

    Examples:
     | result | polyval
     | false  | 0
     | true   | 1
     | true   | True
     | true   | true
     | true   | false
     | true   | FALSE
     | true   | yes
     | true   | no
     | true   | '; delete from foobar; select '


    Scenario Outline: Wrapping of legal jsonp search requests
        When searching for "Tokyo"
        Given format json
        And parameter json_callback as "<data>"
        Then valid json is returned

    Examples:
     | data
     | foo
     | FOO
     | __world
     | $me
     | m1[4]
     | d_r[$d]

    Scenario Outline: Wrapping of illegal jsonp search requests
        When searching for "Tokyo"
        Given format json
        And parameter json_callback as "<data>"
        Then a HTTP 400 is returned

    Examples:
      | data
      | 1asd
      | bar(foo)
      | XXX['bad']
      | foo; evil

    Scenario Outline: Ignore jsonp parameter for anything but json
        When searching for "Malibu"
        Given parameter json_callback as "234"
        Then valid html is returned
        Using format xml
        Then valid search xml is returned
        Using format html
        Then valid html is returned
