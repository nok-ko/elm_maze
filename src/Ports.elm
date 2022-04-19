port module Ports exposing (..)


type alias MazPortData =
    { width : Int
    , height : Int
    , data : List Int
    , filename : String
    }



-- Called when the <input> field changes.


port fileSelected : String -> Cmd msg



-- When the file's been read, this port sends the file info to Elm.


port fileContentRead : (MazPortData -> msg) -> Sub msg
