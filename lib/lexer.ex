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
  """
  @unordered_list_element_re ~r{#{@indentation}(-|\+|\*)\s+(.*)$}
  # TODO: Find a way to do this without nested `?:` words
  @ordered_list_element_re ~r{#{@indentation}((?:[a-zA-z]|\d+)(?:\.|\)))\s+(.*)$}

  # TODO: Don't run the regex twice
  defp process_line(line) do
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
      true ->
	{:unknown, nil, line}
    end
  end
end
