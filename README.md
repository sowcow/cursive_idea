![Example cursive saying: cursive idea](cursive%20idea.png?raw=true)

# What

- Mapping of 26 letters to a potentially new cursive.
- A tabular way to see it.
- Software to preview writing of the given text.
- Also anki deck for the first step of practicing.

![Table with letters](table.png?raw=true)

# Why

Existing shorthands are not invented here.
Also my potential usage is writing random own stuff and not recording somebody's speech.
It has been entertaining regardless of utility.

# It

- removes repetition (as in "m")
- minimizes complexity of curve to streamline every letter

# So

- directly vertical strokes are only optional letter connectors
- five simplest base horizontal strokes
- five different modes of execution
- and one odd letter for the 26th letter of the alphabet

# How

- have ruby and imagemagick installed
- to have only the cursive: $ rake say hello world
- to see the latin mapping too: $ rake show hello world
- check the file named after the text provided: 'hello world.png'
- I tested it on linux but I see no obvious causes of errors otherwise

# But

These are random ideas I've not looked into.

- optimization to minimize vertical strokes
- optimization opportunity to address hand anatomy
- looking into mapping to vocal mechanics would be interesting
- using letter frequency could make the table less reconstructable than current more predictable mechanical mapping
- expanded "long hand" version for more distinct looking letters or just optimize mapping to get similarity in the first place
- optimize using NNs and reduction of recognition error given noise
