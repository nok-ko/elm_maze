module Maze exposing (..)

import Bitwise as Bit
import Browser
import Bytes exposing (Bytes)
import Html exposing (Html, button, div, h1, text)
import Html.Attributes exposing (style)
import Html.Events exposing (..)
import Json.Decode as JD
import List exposing (repeat)
import Ports exposing (MazPortData, fileContentRead, fileSelected)
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


type alias Maze =
    { width : Int
    , height : Int
    , data : List Int
    , filename : String
    }


type alias Model =
    { id : String
    , maze : Maybe Maze
    }


init : () -> ( Model, Cmd Msg )
init _ =
    ( { id = "maze_select", maze = Nothing }
    , Cmd.none
    )



-- UPDATE


type Msg
    = MazSelected
    | MazRead MazPortData


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        MazSelected ->
            ( model
            , fileSelected model.id
            )

        MazRead data ->
            let
                newMaze : Maze
                newMaze =
                    { width = data.width
                    , height = data.height
                    , data = data.data
                    , filename = data.filename
                    }
            in
            ( { model | maze = Just newMaze }
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    fileContentRead MazRead



-- VIEW


view : Model -> Html Msg
view model =
    let
        maze =
            case model.maze of
                Just m ->
                    viewMaze m

                Nothing ->
                    text "No maze?"
    in
    div [ Html.Attributes.class "mazeWrapper" ]
        [ Html.input
            [ Html.Attributes.type_ "file"
            , Html.Attributes.id model.id
            , Html.Events.on "change" (JD.succeed MazSelected)
            ]
            []
        , maze
        ]


groupBy : List (List Int) -> List Int -> Int -> List (List Int)
groupBy soFar rest size =
    if List.length rest == 0 then
        soFar

    else
        groupBy (List.take size rest :: soFar) (List.drop size rest) size


type alias DrawSettings =
    { x : Int
    , y : Int
    , cellSize : Int
    }


isThing : Maybe a -> Maybe a
isThing a =
    a


cell : Int -> DrawSettings -> List (S.Svg msg)
cell mazeData drawS =
    let
        centerX =
            toFloat (drawS.x * drawS.cellSize) + third

        centerY =
            toFloat (drawS.y * drawS.cellSize) + third

        third =
            toFloat drawS.cellSize / 3.0
    in
    -- Always draw the background...
    List.filterMap isThing
        [ -- Just <|
          --   S.rect
          --       [ SA.x <| String.fromInt (drawS.x * drawS.cellSize)
          --       , SA.y <| String.fromInt (drawS.y * drawS.cellSize)
          --       , SA.width <| String.fromInt drawS.cellSize
          --       , SA.height <| String.fromInt drawS.cellSize
          --       , SA.fill "#000"
          --       , SA.id <| String.fromInt mazeData
          --       ]
          --       []
          -- North Passage: (0b1000)
          if Bit.and mazeData 8 == 8 then
            Just <|
                S.rect
                    [ SA.x <| String.fromFloat centerX
                    , SA.y <| String.fromFloat <| centerY - third
                    , SA.width <| String.fromFloat third
                    , SA.height <| String.fromFloat (third * 2)
                    , SA.fill "#fff"
                    ]
                    []

          else
            Nothing

        -- East Passage: (0b0100)
        , if Bit.and mazeData 4 == 4 then
            Just <|
                S.rect
                    [ SA.x <| String.fromFloat centerX
                    , SA.y <| String.fromFloat centerY
                    , SA.width <| String.fromFloat (third * 2)
                    , SA.height <| String.fromFloat third
                    , SA.fill "#fff"
                    ]
                    []

          else
            Nothing

        -- South Passage: 0b0010
        , if Bit.and mazeData 2 == 2 then
            Just <|
                S.rect
                    [ SA.x <| String.fromFloat centerX
                    , SA.y <| String.fromFloat centerY
                    , SA.width <| String.fromFloat third
                    , SA.height <| String.fromFloat (third * 2)
                    , SA.fill "#fff"
                    ]
                    []

          else
            Nothing

        -- West Passage: 0b0001
        , if Bit.and mazeData 1 == 1 then
            Just <|
                S.rect
                    [ SA.x <| String.fromInt (drawS.x * drawS.cellSize)
                    , SA.y <| String.fromFloat centerY
                    , SA.width <| String.fromFloat (2 * third)
                    , SA.height <| String.fromFloat third
                    , SA.fill "#fff"
                    ]
                    []

          else
            Nothing
        ]


rectRows : List (List Int) -> List (S.Svg msg)
rectRows rows =
    let
        height =
            List.length rows

        settings =
            { x = 0, y = 0, cellSize = 9 }
    in
    List.concat <|
        List.concat <|
            List.indexedMap
                (\iy row ->
                    List.indexedMap
                        (\ix n -> cell n { settings | x = ix, y = height - iy - 1 })
                        row
                )
                rows


viewMaze : Maze -> Html Msg
viewMaze maze =
    let
        mazeRows : List (List Int)
        mazeRows =
            groupBy [] maze.data maze.width

        w =
            String.fromInt (maze.width * 9)

        h =
            String.fromInt (maze.height * 9)
    in
    Html.div [ Html.Attributes.class "maze-go-here" ]
        [ S.svg
            [ SA.width w
            , SA.height h
            , SA.viewBox ("0 0 " ++ w ++ " " ++ h)
            ]
            (S.rect [ SA.width w, SA.height h, SA.x "0", SA.y "0" ] []
                :: rectRows mazeRows
            )
        ]
