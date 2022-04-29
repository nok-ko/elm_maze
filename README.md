# elm_maze

<img width="588" alt="image" src="https://user-images.githubusercontent.com/13428215/165879792-675b259e-1794-4870-bcad-00d8ff08a96f.png">

Download a [MAZ](https://github.com/nok-ko/ray_maze/raw/main/mazes/dfs.maz) [file](https://github.com/nok-ko/ray_maze/raw/main/mazes/coolmaze.maz) to view, and then…

[**Launch it!**](https://nok-ko.github.io/elm_maze/)

# What is this?

A [`.MAZ` file](https://nok-ko.github.io/ray_maze/maz_format.html) viewer, written in Elm!

This is a project I made to learn [Elm](https://elm-lang.org/)! It renders MAZ files into SVG on your browser. The file-reading code is written in JavaScript and exposed through a [port](https://guide.elm-lang.org/interop/ports.html) to Elm. (I did this because file-reading code is not part of the Elm standard library, and working with byte arrays is easier in JS.) The SVG-emitting code is written entirely in Elm.

# Further Work…
-  [ ] Support raw/unpacked MAZ files.
-  [ ] Write a maze generator in Elm…
