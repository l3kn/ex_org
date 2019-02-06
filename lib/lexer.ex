defmodule ExOrg.Lexer do
  @moduledoc """
  Process each line of the document,
  determine its type and preprocess it accordingly
  """

  def lex(document) do
    document
    |> String.split(~r{\r?\n}, trim: true)
    |> Enum.map(&process_line/1)
  end

  @indentation "^(\s*)"
  @header_re ~r{^(\*+)\s+(.*)$}

  @doc """
  Quoting from https://orgmode.org/worg/dev/org-syntax.html,
  section "Plain Lists and Items"

  Items are defined by a line starting with the following pattern
  `BULLET COUNTER-SET CHECK-BOX TAG`,
  in which only `BULLET` is mandatory.

  `BULLET` is either an asterisk, a hyphen, a plus sign character
  or follows either the pattern `COUNTER.` or `COUNTER)`.

  NOTE: If it starts with an asterisk, it must be preceeded with whitespace
  to distinguish it from headings.
   
  In any case, `BULLET` is followed by a whitespace character
  or line ending.

  `COUNTER` can be a number or a single letter

  `COUNTER-SET` follows the pattern `[@COUNTER]`.

  `CHECK-BOX` is either a single whitespace character,
  a "X" character or a hyphen, enclosed within square brackets.

  `TAG` follows the `TAG-TEXT ::` pattern,
  where `TAG-TEXT` can contain any character but a new line.

  An item ends before the next item,
  the first line less or equally indented than its starting line,
  or two consecutive empty lines.

  Indentation of lines within other greater elements do not count,
  neither do inlinetask boundaries.

  A plain list is a set of consecutive items of the same indentation.
  It can only directly contain items.

  If the first item in a plain list has a counter in its bullet,
  the plain list will be an "ordered plain-list".
  If it contains a tag, it will be a "descriptive list".
  Otherwise, it will be an "unordered list".

  List types are mutually exclusive.

  NOTE: Because asterisks are allowed as bullet,
  this regex must be run _after_ the one for headers

  TODO: Definition lists are not supported
  """
  @unordered_list_element_re ~r{#{@indentation}(-|\+|\*)\s+(.*)$}
  # TODO: Find a way to do this without nested `?:` words
  @ordered_list_element_re ~r{#{@indentation}((?:[a-zA-z]|\d+)(?:\.|\)))\s+(.*)$}

  @doc """
  Quoting from https://orgmode.org/worg/dev/org-syntax.html,
  section "Greater Blocks"

  Greater blocks consist of the following pattern
  ```
  #+BEGIN_NAME PARAMETERS
  CONTENTS
  #+END_NAME
  ```

  `NAME` can contain any non-whitespace character.
  `PARAMETERS` can contain any character other than `\n`, and can be ommited.

  If `NAME` is "CENTER", it will be a "center block".
  If it is "QUOTE", it will be a "quote block".

  If the block is neither a center block, a quote block or a block element, it will be a "special block".

  `CONTENTS` can contain any element, except: a line `#+END_NAME` on its own.
  Also lines beginning with `STARS` must be quoted by a comma.

  In the section "Blocks" a few more block types are introduced

  * `COMMENT`, "comment block"
  * `EXAMPLE`, "example block"
  * `EXPORT`, "export block"
  * `SRC`, "source block"
  * `VERSE`, "verse block"

  For source and export blocks, `PARAMETERS` can't be ommited.

  For export blocks, it should be constituted of a single word.

  For source blocks, it must be of the form `LANGUAGE SWITCHES ARGUMENTS`
  where `SWITCHES` and `ARGUMENTS` are optional.

  `LANGUAGE` cannot contain any whitespace character.
  `SWITCHES` is made of any number of switch patterns, separated by blank lines
  A switch pattern is either `-l FORMAT` where `FORMAT` can contain any character but a double quote and a new line,
  `-S` or `-S`, where `S` stands for a single letter.

  `ARGUMENTS` can contain any character but a new line.
    
  TODO: Handle center & quote blocks
  TODO: Handle comment, example, export, source, verse block
  TODO: Parse contained org mode elements for verse blocks
  TODO: Raise error on omission of `PARAMETERS` for source and export blocks
  """
  @block_start_re ~r{#{@indentation}\#\+BEGIN_(\S+)( .*)$}
  @block_end_re ~r{#{@indentation}\#\+END_(\S+)$}

  # TODO: Don't run the regex twice
  def process_line(line) do
    cond do
      Regex.match?(@header_re, line) ->
        [_full, stars, body] = Regex.run(@header_re, line)
        {:header, [level: String.length(stars)], body}

      Regex.match?(@unordered_list_element_re, line) ->
        [_full, indent, bullet, body] = Regex.run(@unordered_list_element_re, line)
        {:unordered_list_element, [indentation: String.length(indent), bullet: bullet], body}

      Regex.match?(@ordered_list_element_re, line) ->
        [_full, indent, bullet, body] = Regex.run(@ordered_list_element_re, line)
        {:unordered_list_element, [indentation: String.length(indent), bullet: bullet], body}

      Regex.match?(@block_start_re, line) ->
        [_full, indent, name, params] = Regex.run(@block_start_re, line)

        # Remove the required leading space
        # TODO: This doesn't handle params starting with multiple spaces
        params =
          if String.length(params) > 0 do
            String.slice(params, 1..-1)
          else
            ""
          end

        {:block_start, [indentation: String.length(indent), name: name], params}

      Regex.match?(@block_end_re, line) ->
        [_full, indent, name] = Regex.run(@block_end_re, line)
        {:block_end, [indentation: String.length(indent), name: name], nil}

      true ->
        {:line, nil, line}
    end
  end
end
