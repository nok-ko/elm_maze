module Main exposing (..)

import Browser
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import List exposing (repeat)
import String exposing (fromList, length)
import Svg as S
import Svg.Attributes as SA
import Task
import Time



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type alias Model =
    { zone : Time.Zone
    , time : Time.Posix
    , paused : Bool
    , initialized : Bool
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( Model Time.utc (Time.millisToPosix 0) False False
    , Task.perform AdjustTimeZone Time.here
    )



-- UPDATE


type Msg
    = Tick Time.Posix
    | AdjustTimeZone Time.Zone
    | Pause Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Tick newTime ->
            ( { model | time = newTime }
            , Cmd.none
            )

        AdjustTimeZone newZone ->
            ( { model | zone = newZone, initialized = True }
            , Cmd.none
            )

        Pause newPaused ->
            ( { model | paused = newPaused }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    if model.paused then
        Sub.none

    else
        Time.every 1000 Tick



-- VIEW
-- Helper to get Time.toHour into a clock face value quickly


digit : Model -> (Time.Zone -> Time.Posix -> Int) -> Int
digit model rawDigits =
    rawDigits model.zone model.time



-- Hour/Minute/Second representation


type alias HMS =
    { h : Int
    , m : Int
    , s : Int
    }


toHMS : Model -> HMS
toHMS model =
    { h = digit model Time.toHour
    , m = digit model Time.toMinute
    , s = digit model Time.toSecond
    }



-- Take two numbers, value and max, produce a float
-- representing that many rotations around a circle.


clockToTrig : Int -> Int -> Float
clockToTrig val max =
    let
        tau =
            2 * pi
    in
    ((toFloat val / toFloat max) - 0.25) * tau



-- Type representing geometric information about an analog clock hand


type alias HandInfo =
    { val : Int -- Value of this digit of the clock
    , max : Int -- Maximum value this digit can have
    , ox : Float -- X-coordinate of the centre of this clock
    , oy : Float -- Y-coordinate of the centre
    , r : Float -- Radius of the whole clock
    , fac : Float -- How big the hand should be, relative to the clock
    }



-- Helper that emits an analog clock hand <line> element


hand : HandInfo -> List (S.Attribute Msg) -> List (S.Svg Msg) -> S.Svg Msg
hand handInfo attrs children =
    let
        c =
            handInfo.val

        ox =
            handInfo.ox

        oy =
            handInfo.oy

        radius =
            handInfo.r * handInfo.fac

        max =
            handInfo.max
    in
    S.line
        (List.append
            attrs
            [ SA.x2 <| String.fromFloat ((cos (clockToTrig c max) * radius) + ox)
            , SA.y2 <| String.fromFloat ((sin (clockToTrig c max) * radius) + oy)
            ]
        )
        children


clock : Model -> S.Svg Msg
clock model =
    let
        hms =
            toHMS model

        cx =
            60

        cy =
            60

        r =
            50

        handTemplate : HandInfo
        handTemplate =
            { val = 0
            , max = 60
            , r = r
            , ox = cx
            , oy = cy
            , fac = 1.0
            }

        -- Clock centre is the same for each hand
        handAttrs =
            [ SA.x1 <| String.fromFloat cx, SA.y1 <| String.fromFloat cy ]
    in
    S.svg []
        [ S.circle
            [ SA.cx <| String.fromFloat cx
            , SA.cy <| String.fromFloat cy
            , SA.r <| String.fromFloat r
            , SA.stroke "black"
            , SA.fill "none"
            ]
            []

        -- The second Hand. This one is red!
        , hand
            { handTemplate | val = hms.s, fac = 0.9 }
            (SA.strokeWidth "1px" :: SA.stroke "red" :: handAttrs)
            []

        -- The minute Hand
        , hand
            { handTemplate | val = hms.m, fac = 0.8 }
            (SA.strokeWidth "2px" :: SA.stroke "black" :: handAttrs)
            []

        -- The hour hand: maximum is 12 but we get a 0-24 value, so use
        -- modBy to reduce the range.
        , hand
            { handTemplate | val = modBy 12 hms.h, fac = 0.5 }
            (SA.strokeWidth "2px" :: SA.stroke "black" :: handAttrs)
            []
        ]



-- Helper to zero-pad clock face digits


zeroPad : Int -> String -> String
zeroPad pad string =
    let
        toPad =
            pad - length string
    in
    fromList (repeat toPad '0') ++ string


view : Model -> Html Msg
view model =
    let
        hour =
            modBy 12 (digit model Time.toHour)
                |> String.fromInt
                |> zeroPad 2

        minute =
            digit model Time.toMinute
                |> String.fromInt
                |> zeroPad 2

        second =
            digit model Time.toSecond
                |> String.fromInt
                |> zeroPad 2

        paused =
            model.paused

        initialized =
            model.initialized

        meridian : String
        meridian =
            if digit model Time.toHour >= 13 then
                "PM"

            else
                "AM"
    in
    div []
        (if initialized then
            [ h1 [ style "font-family" "sans-serif" ]
                [ text (hour ++ ":" ++ minute ++ ":" ++ second ++ " " ++ meridian) ]
            , button [ onClick (Pause (not paused)) ]
                [ text
                    (if paused then
                        "Resume!"

                     else
                        "Pause!"
                    )
                ]
            , clock model
            ]

         else
            []
        )
